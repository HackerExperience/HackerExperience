defmodule Game.Scanner.Log do
  @behaviour Game.Scanner.Scanneable

  alias Game.{ScannerTask}
  alias Game.Services, as: Svc
  alias Game.Scanner.Params.Log, as: LogParams

  # Prioritize scans on 25% most recent logs
  @recent_factor 0.25

  def retarget(%ScannerTask{
        type: :log,
        instance_id: instance_id,
        server_id: server_id,
        entity_id: entity_id
      }) do
    %{target_params: target_params} = Svc.Scanner.fetch_instance!(by_id: instance_id)

    # TODO: Consider changing the Core.Fetch API so it receives a single `opts` list.
    visibilities =
      Svc.Log.list_visibility(entity_id, [by_server: server_id],
        format: :raw,
        select: [:log_id, :revision_id]
      )

    # TODO: `by_scanneable` filters out deleted logs, which is not the goal in *some* scenarios
    logs =
      Svc.Log.list(server_id, [by_scanneable: []],
        format: :raw,
        select: [:id, :revision_id]
      )

    case find_log(
           {logs, length(logs)},
           {visibilities, length(visibilities)},
           {LogParams.empty?(target_params), target_params}
         ) do
      [log_id, revision_id] ->
        # TODO: duration
        {:ok, {log_id, revision_id}, 60}

      :empty ->
        {:ok, :empty}
    end
  end

  # There are no logs in the Server
  def find_log({_, 0}, _, _), do: :empty

  def find_log({logs, len_logs}, {visibilities, _len_visibilities}, {true, _}) do
    # Let's focus initial lookup on the @recent_factor% most recent log entries
    recent_n = :math.ceil(len_logs * @recent_factor) |> trunc()
    {recent_logs, _older_logs} = Enum.split(logs, recent_n)

    ms_visibilities = MapSet.new(visibilities)

    selected_log =
      case find_random(MapSet.new(recent_logs), ms_visibilities) do
        :empty ->
          # Try again with the whole dataset
          find_random(MapSet.new(logs), ms_visibilities)

        [log_id, rev_id] ->
          [log_id, rev_id]
      end

    with [selected_log_id, selected_revision_id] <- selected_log do
      # Let's make sure this selected log contains the correct revision ID.
      # Since this selection is random, if the user already has *some* visibility over it, we need
      # to make sure that the selected revision is (current_revision - 1), necessarily.
      [selected_log_id, selected_revision_id]

      most_recent_visibility =
        visibilities
        |> Enum.filter(fn [log_id, _] -> log_id == selected_log_id end)
        |> Enum.sort()
        |> List.first()

      case most_recent_visibility do
        nil ->
          # Player has no existing visibility over this log, revision should be the last one
          logs
          |> Enum.filter(fn [log_id, _] -> log_id == selected_log_id end)
          |> Enum.sort()
          |> List.last()

        [^selected_log_id, most_recent_revision_id] ->
          # Player already has visibility on this specific log; return the next revision
          [selected_log_id, most_recent_revision_id - 1]
      end
    end
  end

  def find_log(_logs, _visibilities, {false, _target_params}) do
    raise "TODO: find_log with target_params"
  end

  defp find_random(ms_logs, ms_visibilities) do
    diff = MapSet.difference(ms_logs, ms_visibilities)

    if MapSet.size(diff) == 0 do
      :empty
    else
      diff
      |> MapSet.to_list()
      |> Enum.random()
    end
  end
end
