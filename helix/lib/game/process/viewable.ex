defmodule Game.Process.Viewable do
  use Norm
  import Core.Spec
  alias Core.ID
  alias Game.Process

  def spec do
    selection(
      schema(%{
        __openapi_name: "IdxProcess",
        process_id: external_id(),
        type: binary(),
        data: binary()
      }),
      [:process_id, :type, :data]
    )
  end

  def spec(:nip) do
    selection(
      schema(%{
        nip: nip(),
        process_id: external_id(),
        type: binary(),
        data: binary()
      }),
      [:nip, :process_id, :type, :data]
    )
  end

  def render(%Process{data: %process_mod{}} = process, entity_id) do
    viewable = get_viewable_mod(process_mod)
    data = apply(viewable, :render_data, [process, process.data, entity_id])

    %{
      process_id: ID.to_external(process.id, entity_id, process.server_id),
      type: "#{process.type}",
      data: serialize_data(data)
    }
  end

  def get_viewable_mod(process_mod),
    do: Module.concat(process_mod, :Viewable)

  defp serialize_data(data) when is_map(data) do
    data
    |> :json.encode()
    |> to_string()
  end
end
