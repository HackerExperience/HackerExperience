defmodule Test.Setup.Scanner do
  use Test.Setup.Definition
  alias Game.{ScannerInstance}

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

  def instance_params(opts \\ []) do
    %{
      id: Kw.get(opts, :id, Random.int()),
      entity_id: Kw.get(opts, :entity_id, R.entity_id()),
      server_id: Kw.get(opts, :server_id, R.server_id()),
      type: Kw.get(opts, :type, Enum.random(ScannerInstance.types())),
      tunnel_id: Kw.get(opts, :tunnel_id, nil),
      target_params: Kw.get(opts, :target_params, %{})
    }
  end
end
