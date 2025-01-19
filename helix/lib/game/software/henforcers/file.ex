defmodule Game.Henforcers.File do
  alias Core.Henforcer
  alias Game.Henforcers
  alias Game.Services, as: Svc
  alias Game.{Entity, File, FileVisibility, Server}

  @type file_exists_relay :: %{file: File.t()}
  @type file_exists_error :: {false, {:file, :not_found}, %{}}

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
  @type is_visible_error :: {false, {:file_visibility, :not_found}, %{}}

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

  @type can_install_relay :: %{visibility: FileVisibility.t(), file: File.t(), entity: Entity.t()}
  @type can_install_error ::
          Henforcers.Server.belongs_to_entity_error()
          | file_exists_error
          | is_visible_error

  @doc """
  Aggregator that henforces that the given Entity can install the given File in the given Server.

  Used by the corresponding Endpoint and Process (FileInstallEndpoint and FileInstallProcess).
  """
  @spec can_install?(Server.t(), Entity.t(), File.id()) ::
          {true, can_install_relay}
          | can_install_error
  def can_install?(%Server{} = server, %Entity{} = entity, %File.ID{} = file_id) do
    with {true, %{entity: entity}} <- Henforcers.Server.belongs_to_entity?(server, entity),
         {true, %{file: file}} <- file_exists?(file_id, server),
         {true, %{visibility: visibility}} <- is_visible?(file, entity.id) do
      Henforcer.success(%{file: file, visibility: visibility})
    end
  end

  def can_delete?(%Server{} = server, %Entity{} = entity, %File.ID{} = file_id) do
    with {true, %{file: file}} <- file_exists?(file_id, server),
         {true, %{visibility: visibility}} <- is_visible?(file, entity.id) do
      Henforcer.success(%{file: file, visibility: visibility})
    end
  end
end
