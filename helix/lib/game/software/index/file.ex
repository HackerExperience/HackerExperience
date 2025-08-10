defmodule Game.Index.File do
  use Norm
  import Core.Spec
  alias Core.ID
  alias Game.Services, as: Svc
  alias Game.{Entity, File, Server, Software}

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
        path: binary()
      }),
      [:id, :name, :type, :size, :version, :path]
    )
  end

  @doc """
  Returns a list of every File `entity_id` can see in `server_id`.

  Order is not relevant (yet?).
  """
  @spec index(Entity.id(), Server.id()) ::
          index
  def index(entity_id, server_id) do
    visible_files = Svc.File.list_visibility(entity_id, visible_on_server: server_id)

    # Fetch each visible file. Handle the DB context outside to avoid excessive context switching
    Core.with_context(:server, server_id, :read, fn ->
      Enum.map(visible_files, fn [raw_file_id] ->
        Svc.File.fetch(server_id, by_id: raw_file_id)
      end)
    end)
  end

  @spec render_index(index, Entity.id()) ::
          rendered_index
  def render_index(index, entity_id) do
    Enum.map(index, &render_file(&1, entity_id))
  end

  @spec render_file(File.t(), Entity.id()) ::
          rendered_file
  def render_file(%File{} = file, entity_id) do
    %{
      id: ID.to_external(file.id, entity_id, file.server_id),
      name: "#{file.name}",
      type: "#{file.type}",
      version: file.version,
      size: file.size,
      path: file.path
    }
  end
end
