defmodule Game.Index.File do
  use Norm
  import Core.Spec
  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.{Entity, File, Installation, Server, Software}

  @type index ::
          term

  @type rendered_index ::
          [rendered_file]

  @typep rendered_file :: %{
           id: ID.external(),
           name: binary(),
           type: binary(),
           version: integer(),
           size: integer(),
           path: binary()
         }

  def spec do
    selection(
      schema(%{
        __openapi_name: "IdxFile",
        id: external_id(),
        name: binary(),
        type: enum(Software.types(:all) |> Enum.map(&to_string/1)),
        size: integer(),
        version: integer(),
        path: binary(),
        installation_id: maybe(external_id())
      }),
      [:id, :name, :type, :size, :version, :path, :installation_id]
    )
  end

  @doc """
  Returns a list of every File `entity_id` can see in `server_id`.

  Order is not relevant (yet?).
  """
  @spec index(Entity.id(), Server.id(), [Installation.t()]) ::
          index
  def index(entity_id, server_id, installations) do
    visible_files = Svc.File.list_visibility(entity_id, visible_on_server: server_id)
    installations_by_file_id = Enum.group_by(installations, & &1.file_id)

    # Fetch each visible file. Handle the DB context outside to avoid excessive context switching
    Core.with_context(:server, server_id, :read, fn ->
      Enum.map(visible_files, fn [raw_file_id] ->
        server_id
        |> Svc.File.fetch(by_id: raw_file_id)
        |> maybe_inject_installation_id(installations_by_file_id)
      end)
    end)
  end

  defp maybe_inject_installation_id(file, installations) do
    case installations[file.id] do
      [%Installation{id: installation_id}] ->
        {file, installation_id}

      nil ->
        {file, nil}
    end
  end

  @spec render_index(index, Entity.id()) ::
          rendered_index
  def render_index(index, entity_id) do
    Enum.map(index, &render_file(&1, entity_id))
  end

  @spec render_file({File.t(), Installation.id() | nil}, Entity.id()) ::
          rendered_file
  def render_file({%File{} = file, maybe_installation_id}, entity_id) do
    %{
      id: ID.to_external(file.id, entity_id, file.server_id),
      name: "#{file.name}",
      type: "#{file.type}",
      version: file.version,
      size: file.size,
      path: file.path,
      installation_id: ID.to_external(maybe_installation_id, entity_id, file.server_id)
    }
  end
end
