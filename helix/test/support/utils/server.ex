defmodule Test.Utils.Server do
  alias Feeb.DB
  alias Game.Services, as: Svc
  alias Game.{Process, Server, ServerMeta}

  def update_resources(%Server.ID{} = server_id, resources) do
    meta = Svc.Server.get_meta(server_id)

    new_resources =
      meta.resources
      |> Map.from_struct()
      |> Enum.map(fn {res, v} ->
        {res, resources[res] |> Renatils.Decimal.to_decimal() || v}
      end)
      |> Map.new()
      |> Process.Resources.from_map()

    Core.with_context(:server, server_id, :write, fn ->
      meta
      |> ServerMeta.update(%{resources: new_resources})
      |> DB.update!()
    end)
  end
end
