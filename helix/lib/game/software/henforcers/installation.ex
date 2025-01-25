defmodule Game.Henforcers.Installation do
  alias Core.Henforcer
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

  @type can_uninstall_relay :: %{installation: Installation.t()}
  @type can_uninstall_error ::
          exists_error

  @doc """
  Aggregator that henforces that the given Entity can uninstall the given Installation in the given
  Server.

  Used by the corresponding Endpoint and Process (InstallationUninstallEndpoint and
  InstallationUninstallProcess).
  """
  @spec can_uninstall?(Server.t(), Entity.t(), Installation.id()) ::
          {true, can_uninstall_relay}
          | can_uninstall_error
  def can_uninstall?(%Server{} = server, %Entity{} = _entity, %Installation.ID{} = installation_id) do
    with {true, %{installation: installation}} <- exists?(installation_id, server) do
      Henforcer.success(%{installation: installation})
    end
  end
end
