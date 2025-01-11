defmodule Test.Setup.Process.Spec do
  use Test.Setup.Definition

  alias Game.Process.Executable

  alias Game.Process.Log.Edit, as: LogEditProcess
  alias Test.Process.NoopCPU, as: NoopCPUProcess
  alias Test.Process.NoopDLK, as: NoopDLKProcess

  @implementations [
    :log_edit
  ]

  @doc """
  Grabs a random (non-test) implementation and use it as type for the spec.
  """
  def random(server_id, entity_id, opts) do
    @implementations
    |> Enum.take_random(1)
    |> List.first()
    |> spec(server_id, entity_id, opts)
  end

  def spec(:noop_cpu, server_id, entity_id, _opts),
    do: build_spec(NoopCPUProcess, server_id, entity_id, %{}, %{})

  def spec(:noop_dlk, server_id, entity_id, _opts),
    do: build_spec(NoopDLKProcess, server_id, entity_id, %{}, %{})

  def spec(:log_edit, server_id, entity_id, opts) do
    default_params = fn ->
      # This is actually TODO; it should come from a Setup.Log.Data util
      {log_type, log_data} = opts[:log_info] || {:local_login, %Game.Log.Data.EmptyData{}}
      %{type: log_type, data: log_data}
    end

    default_meta = fn ->
      log = opts[:log] || S.log!(server_id)
      %{log: log}
    end

    params = opts[:params] || default_params.()
    meta = opts[:meta] || default_meta.()

    build_spec(LogEditProcess, server_id, entity_id, params, meta)
  end

  defp build_spec(mod, server_id, entity_id, params, meta) do
    executable = Module.concat(mod, :Executable)

    {registry_data, process_info} =
      Executable.get_params(executable, [server_id, entity_id, params, meta])

    %{
      module: mod,
      type: mod.get_process_type(params, meta),
      data: mod.new(params, meta),
      params: params,
      meta: meta,
      server_id: server_id,
      registry_data: registry_data,
      process_info: process_info
    }
  end
end
