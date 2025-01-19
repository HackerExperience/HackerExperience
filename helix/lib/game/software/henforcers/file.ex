defmodule Game.Henforcers.File do
  alias Core.Henforcer
  alias Game.Services, as: Svc
  alias Game.{Entity, File, FileVisibility, Server}

  @type file_exists_relay :: %{file: File.t()}
  @type file_exists_error :: {false, {:file, :not_Found}, %{}}

  @doc """
  Checks whether the given File exists.
  """
  @spec file_exists?(File.ID.t(), Server.t()) ::
          {true, file_exists_relay}
          | file_exists_error
  def file_exists?(%File.ID{} = file_id, %Server{} = server) do
    Core.with_context(:server, server.id, :read, fn ->
      case Svc.File.fetch(by_id: file_id) do
        %File{} = file ->
          Henforcer.success(%{file: file})

        nil ->
          Henforcer.fail({:file, :not_found})
      end
    end)
  end

  @type is_visible_relay :: %{visibility: FileVisibility.t()}
  @type is_visible_error :: {:file_visibility, :not_found}

  @doc """
  Henforces that the given `entity_id` has Visibility into the given `file`.
  """
  @spec is_visible?(File.t(), Entity.id()) ::
          {true, is_visible_relay}
          | is_visible_error
  def is_visible?(%File{} = file, %Entity.ID{} = entity_id) do
    case Svc.File.fetch_visibility(entity_id, by_file: file) do
      %FileVisibility{} = visibility ->
        Henforcer.success(%{visibility: visibility})

      nil ->
        Henforcer.fail({:file_visibility, :not_found})
    end
  end
end
