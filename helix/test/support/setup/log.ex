defmodule Test.Setup.Log do
  use Test.Setup.Definition
  alias Game.{Log, LogVisibility}

  def new(server_id, opts \\ []) do
    Core.with_context(:server, server_id, :write, fn ->
      log =
        opts
        |> params()
        |> Log.new()
        |> DB.insert!()

      log_visibility =
        if Keyword.has_key?(opts, :visible_by) do
          entity_id = Keyword.fetch!(opts, :visible_by)

          new_visibility!(entity_id,
            server_id: server_id,
            log_id: log.id,
            revision_id: log.revision_id
          )
        end

      %{log: log, log_visibility: log_visibility}
    end)
  end

  def new!(server_id, opts \\ []),
    do: server_id |> new(opts) |> Map.fetch!(:log)

  # def new_revision(server_id, original_log, opts \\ []) do
  # end

  def new_visibility(player_id, opts \\ []) do
    Core.with_context(:player, player_id, :write, fn ->
      log_visibility =
        opts
        |> visibility_params()
        |> LogVisibility.new()
        |> DB.insert!()

      %{log_visibility: log_visibility}
    end)
  end

  def new_visibility!(player_id, opts \\ []),
    do: player_id |> new_visibility(opts) |> Map.fetch!(:log_visibility)

  def params(opts \\ []) do
    {deleted_at, deleted_by} =
      if Kw.has_key?(opts, :is_deleted) || Kw.has_key?(opts, :deleted_at) ||
           Kw.has_key?(opts, :deleted_by) do
        {Kw.get(opts, :deleted_at, DateTime.utc_now()), Kw.get(opts, :deleted_by, 1)}
      else
        {nil, nil}
      end

    %{
      id: Kw.get(opts, :id, Random.int()),
      revision_id: Kw.get(opts, :revision_id, 1),
      type: Kw.get(opts, :type, :server_login),
      direction: Kw.get(opts, :direction, :self),
      data: Kw.get(opts, :data, %Log.Data.EmptyData{}),
      deleted_at: deleted_at,
      deleted_by: deleted_by
    }
  end

  def visibility_params(opts \\ []) do
    %{
      server_id: Kw.get(opts, :server_id, Random.int()),
      log_id: Kw.get(opts, :log_id, Random.int()),
      revision_id: Kw.get(opts, :revision_id, 1),
      source: Kw.get(opts, :source, :self)
    }
  end
end
