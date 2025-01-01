defmodule Test.Utils.Process do
  use Test.Setup.Definition

  alias Game.Server

  def execute(server_id_or_spec, optional_opts \\ [])

  def execute(%Server.ID{} = server_id, opts) do
    server_id
    |> S.process_spec(opts)
    |> execute()
  end

  def execute(spec, _) when is_map(spec),
    do: Svc.TOP.execute(spec.module, spec.server_id, spec.params, spec.meta)
end
