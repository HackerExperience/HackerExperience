defmodule Game.Index.Scanner do
  use Norm
  import Core.Spec
  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.{ScannerInstance}

  @type index :: [ScannerInstance.t()]

  @type rendered_index :: [rendered_instance]

  @typep rendered_instance :: %{
           id: ID.external()
         }

  def spec do
    selection(
      schema(%{
        __openapi_name: "IdxScannerInstance",
        id: external_id(),
        type: enum(ScannerInstance.types() |> Enum.map(&to_string/1))
      }),
      [:id, :type]
    )
  end

  def index(entity_id, server_id) do
    Svc.Scanner.list_instances(by_entity_server: [entity_id, server_id])
  end

  def render_index(index, entity_id) do
    Enum.map(index, &render_instance(&1, entity_id))
  end

  def render_instance(%ScannerInstance{} = instance, entity_id) do
    %{
      id: ID.to_external(instance.id, entity_id),
      type: "#{instance.type}"
    }
  end
end
