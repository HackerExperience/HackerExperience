defmodule Game.Index.Installation do
  use Norm
  import Core.Spec
  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.{Entity, Installation, Server, Software}

  @type index ::
          term

  @type rendered_index ::
          [rendered_installation]

  @typep rendered_installation :: %{
           id: ID.external(),
           file_id: ID.external() | nil,
           file_type: binary(),
           file_version: integer(),
           memory_usage: integer()
         }

  def spec do
    selection(
      schema(%{
        __openapi_name: "IdxInstallation",
        id: external_id(),
        file_id: maybe(external_id()),
        file_type: enum(Software.types(:all) |> Enum.map(&to_string/1)),
        file_version: integer(),
        memory_usage: integer()
      }),
      [:id, :file_id, :file_type, :file_version, :memory_usage]
    )
  end

  @doc """
  Returns a list of every Installation in `server_id`.
  """
  @spec index(Server.id()) ::
          index
  def index(server_id) do
    Svc.Installation.list(server_id, all: true)
  end

  @spec render_index(index, Entity.id()) ::
          rendered_index
  def render_index(index, entity_id) do
    Enum.map(index, &render_installation(&1, entity_id))
  end

  @spec render_installation(Installation.t(), Entity.id()) ::
          rendered_installation
  def render_installation(%Installation{} = installation, entity_id) do
    maybe_file_id =
      if not is_nil(installation.file_id) do
        ID.to_external(installation.file_id, entity_id, installation.server_id)
      end

    %{
      id: ID.to_external(installation.id, entity_id, installation.server_id),
      file_id: maybe_file_id,
      file_type: "#{installation.file_type}",
      file_version: installation.file_version,
      memory_usage: installation.memory_usage
    }
  end
end
