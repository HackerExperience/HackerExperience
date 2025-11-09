defmodule Test.Setup.Scanner do
  use Test.Setup.Definition
  alias Game.{ScannerInstance, ScannerTask}

  alias Game.Scanner.Params.Connection, as: ConnParams
  alias Game.Scanner.Params.File, as: FileParams
  alias Game.Scanner.Params.Log, as: LogParams

  def new_instance(opts \\ []) do
    Core.with_context(:scanner, :write, fn ->
      instance =
        opts
        |> instance_params()
        |> ScannerInstance.new()
        |> DB.insert!()

      %{instance: instance}
    end)
  end

  def new_instance!(opts \\ []),
    do: opts |> new_instance() |> Map.fetch!(:instance)

  def new_instances(opts) do
    opts = Keyword.drop(opts, [:all, :type])

    %{instance: instance_log} = new_instance(opts ++ [type: :log])

    opts =
      opts
      |> Keyword.put_new(:entity_id, instance_log.entity_id)
      |> Keyword.put_new(:server_id, instance_log.server_id)

    %{instance: instance_file} = new_instance(opts ++ [type: :file])
    %{instance: instance_connection} = new_instance(opts ++ [type: :connection])

    %{instances: [instance_log, instance_file, instance_connection]}
  end

  def new_instances!(opts \\ []),
    do: opts |> new_instances() |> Map.fetch!(:instances)

  def new_task(opts \\ []) do
    Core.with_context(:scanner, :write, fn ->
      instance =
        cond do
          opts[:instance] ->
            opts[:instance]

          opts[:instance_id] ->
            Svc.Scanner.fetch_instance!(by_id: opts[:instance_id])

          true ->
            type = opts[:type] || Enum.random(ScannerInstance.types())
            new_instance!(type: type)
        end

      ts_now = Renatils.DateTime.ts_now()

      completion_date =
        if opts[:completed] do
          ts_now - 1
        else
          Kw.get(opts, :completion_date, ts_now + 600)
        end

      task =
        [
          instance_id: instance.id,
          type: instance.type,
          server_id: instance.server_id,
          entity_id: instance.entity_id,
          completion_date: completion_date
        ]
        |> Keyword.merge(opts)
        |> task_params()
        |> ScannerTask.new()
        |> DB.insert!()

      %{task: task, instance: instance}
    end)
  end

  def new_task!(opts \\ []),
    do: opts |> new_task() |> Map.fetch!(:task)

  def instance_params(opts \\ []) do
    type = Kw.get(opts, :type, Enum.random(ScannerInstance.types()))

    default_params =
      case type do
        :connection -> %ConnParams{}
        :file -> %FileParams{}
        :log -> %LogParams{}
      end

    %{
      id: Kw.get(opts, :id, Random.int()),
      entity_id: Kw.get(opts, :entity_id, R.entity_id()),
      server_id: Kw.get(opts, :server_id, R.server_id()),
      type: type,
      tunnel_id: Kw.get(opts, :tunnel_id, nil),
      target_params: Kw.get(opts, :target_params, default_params)
    }
  end

  def task_params(opts \\ []) do
    %{
      instance_id: Kw.get(opts, :instance_id, Random.int()),
      run_id: Kw.get(opts, :run_id, Random.uuid()),
      entity_id: Kw.get(opts, :entity_id, R.entity_id()),
      server_id: Kw.get(opts, :server_id, R.server_id()),
      type: Kw.get(opts, :type, Enum.random(ScannerInstance.types())),
      target_id: Kw.get(opts, :target_id, nil),
      target_sub_id: Kw.get(opts, :target_sub_id, nil),
      scheduled_at: Kw.get(opts, :scheduled_at, DateTime.utc_now()),
      completion_date: Kw.get(opts, :completion_date, Renatils.DateTime.ts_now() + 600),
      next_backoff: Kw.get(opts, :next_backoff),
      failed_attempts: Kw.get(opts, :failed_attempts, 0)
    }
  end
end
