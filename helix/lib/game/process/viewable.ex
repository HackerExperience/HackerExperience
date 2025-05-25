defmodule Game.Process.Viewable do
  alias Core.ID
  alias Game.Process

  def render(%Process{data: %process_mod{}} = process, entity_id) do
    viewable = get_viewable(process_mod)
    data = apply(viewable, :render_data, [process, process.data, entity_id])

    %{
      id: ID.to_external(process.id, entity_id, process.server_id),
      type: "#{process.type}",
      data: serialize_data(data)
    }
  end

  defp serialize_data(data) when is_map(data) do
    data
    |> :json.encode()
    |> to_string()
  end

  defp get_viewable(process_mod),
    do: Module.concat(process_mod, :Viewable)
end
