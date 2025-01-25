defmodule Game.Henforcers.Installation do
  alias Core.Henforcer
  alias Game.Henforcers
  alias Game.Services, as: Svc
  alias Game.{Entity, Installation, Server}

  @type exists_relay :: %{installation: Installation.t()}
  @type exists_error :: {false, {:installation, :not_found}, %{}}

  @doc """
  Checks whether the given Installation exists.
  """
  @spec exists?(Installation.id(), Server.t()) ::
          {true, exists_relay}
          | exists_error
  def exists?(%Installation.ID{} = installation_id, %Server{} = server) do
    case Svc.Installation.fetch(server.id, by_id: installation_id) do
      %Installation{} = installation ->
        Henforcer.success(%{installation: installation})

      nil ->
        Henforcer.fail({:installation, :not_found})
    end
  end

  @type can_uninstall_relay :: %{
          installation: Installation.t(),
          server: Server.t(),
          entity: Entity.t()
        }
  @type can_uninstall_error ::
          exists_error
          | Henforcers.Server.belongs_to_entity_error()
          | Henforcers.Server.server_exists_error()
          | Henforcers.Entity.entity_exists_error()

  @doc """
  Aggregator that henforces that the given Entity can uninstall the given Installation in the given
  Server. Since Install/Uninstall operations are local only, we enforce that the Server belongs to
  the same Entity.

  Used by the corresponding Endpoint and Process (InstallationUninstallEndpoint and
  InstallationUninstallProcess).
  """
  @spec can_uninstall?(Server.idt(), Entity.idt(), Installation.id()) ::
          {true, can_uninstall_relay}
          | can_uninstall_error
  def can_uninstall?(%Server{} = server, %Entity{} = entity, %Installation.ID{} = installation_id) do
    with {true, _} <- Henforcers.Server.belongs_to_entity?(server, entity),
         {true, %{installation: installation}} <- exists?(installation_id, server) do
      Henforcer.success(%{installation: installation, server: server, entity: entity})
    end
  end

  def can_uninstall?(%Server.ID{} = server_id, entity, installation_id) do
    with {true, %{server: server}} <- Henforcers.Server.server_exists?(server_id) do
      can_uninstall?(server, entity, installation_id)
    end
  end

  def can_uninstall?(server, %Entity.ID{} = entity_id, installation_id) do
    with {true, %{entity: entity}} <- Henforcers.Entity.entity_exists?(entity_id) do
      can_uninstall?(server, entity, installation_id)
    end
  end
end
