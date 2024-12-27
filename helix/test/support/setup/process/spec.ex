defmodule Test.Setup.Process.Spec do
  use Test.Setup.Definition
  alias Game.Process.Log.Edit, as: LogEditProcess

  @implementations [
    :log_edit
  ]

  def random(server_id, opts) do
    @implementations
    |> Enum.take_random(1)
    |> List.first()
    |> spec(server_id, opts)
  end

  def spec(:log_edit, server_id, opts) do
    mod = LogEditProcess

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

    build_spec(LogEditProcess, params, meta)
  end

  defp build_spec(mod, params, meta) do
    %{
      module: mod,
      type: mod.get_process_type(params, meta),
      data: mod.new(params, meta),
      params: params,
      meta: meta
    }
  end
end
