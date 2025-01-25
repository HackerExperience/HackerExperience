defmodule Game.Henforcers.Server do
  alias Core.Henforcer
  alias Core.NIP
  alias Game.Services, as: Svc
  alias Game.Henforcers
  alias Game.{Entity, Process, Server, Tunnel}

  @type server_exists_relay :: %{server: term()}
  @type server_exists_error :: {false, {:server, :not_found}, %{}}

  @spec server_exists?(server_id :: term) ::
          {true, server_exists_relay}
          | server_exists_error
  def server_exists?(%Server.ID{} = server_id) do
    case Svc.Server.fetch(by_id: server_id) do
      %_{} = server ->
        Henforcer.success(%{server: server})

      nil ->
        Henforcer.fail({:server, :not_found})
    end
  end

  @type belongs_to_entity_relay :: %{server: Server.t(), entity: Entity.t()}
  @type belongs_to_entity_error :: {false, {:server, :not_belongs}, %{}}

  @doc """
  Henforces that the given Server belongs to the given Entity.
  """
  @spec belongs_to_entity?(Server.idt(), Entity.idt()) ::
          {true, belongs_to_entity_relay}
          | belongs_to_entity_error
  def belongs_to_entity?(%Server.ID{} = server_id, entity) do
    with {true, %{server: server}} <- server_exists?(server_id) do
      belongs_to_entity?(server, entity)
    end
  end

  def belongs_to_entity?(server, %Entity.ID{} = entity_id) do
    with {true, %{entity: entity}} <- Henforcers.Entity.entity_exists?(entity_id) do
      belongs_to_entity?(server, entity)
    end
  end

  def belongs_to_entity?(%Server{} = server, %Entity{} = entity) do
    if server.entity_id == entity.id do
      Henforcer.success(%{server: server, entity: entity})
    else
      Henforcer.fail({:server, :not_belongs})
    end
  end

  @type has_access_relay ::
          %{
            gateway: Server.t(),
            endpoint: Server.t() | nil,
            target: Server.t(),
            tunnel: Tunnel.t() | nil,
            entity: Entity.t(),
            access_type: :local | :remote
          }

  @type has_access_error ::
          Henforcers.Entity.entity_exists_error()
          | Henforcers.Network.tunnel_exists_error()
          | Henforcers.Network.nip_exists_error()
          | belongs_to_entity_error
          | server_exists_error

  @doc """
  "Alternative" entrypoint to the `has_access?/3` function, in which we extract the relevant
  information. Useful to simplify the Henforcer pipeline at the corresponding processes.
  """
  @spec has_access?(Process.t()) ::
          {true, has_access_relay}
          | has_access_error
  def has_access?(%Process{server_id: server_id, entity_id: entity_id, registry: registry}) do
    has_access?(entity_id, server_id, registry[:src_tunnel_id])
  end

  @doc """
  Henforces that the given Entity has access to the given Server (represented by its ID or NIP).
  This can be either for local access (no Tunnel set) or remote access (with Tunnel).

  For local access, Entity will always have access as long as the Server is actually hers.

  For remote access, Entity will have access if all the conditions below are met:
  - The given Tunnel is open
  - The Tunnel belongs to Entity
  - The Tunnel originates in a Server owned by Entity
  - The Tunnel targets the Server that the Entity is trying to access
  """
  @spec has_access?(Entity.idt(), Server.idt() | NIP.t(), Tunnel.idt() | nil) ::
          {true, has_access_relay}
          | has_access_error
  def has_access?(%Entity.ID{} = entity_id, server_or_nip, tunnel) do
    with {true, %{entity: entity}} <- Henforcers.Entity.entity_exists?(entity_id) do
      has_access?(entity, server_or_nip, tunnel)
    end
  end

  def has_access?(entity, server_or_nip, %Tunnel.ID{} = tunnel_id) do
    with {true, %{tunnel: tunnel}} <- Henforcers.Network.tunnel_exists?(tunnel_id) do
      has_access?(entity, server_or_nip, tunnel)
    end
  end

  def has_access?(entity, %NIP{} = nip, tunnel) do
    with {true, %{server: server}} <- Henforcers.Network.nip_exists?(nip) do
      has_access?(entity, server, tunnel)
    end
  end

  def has_access?(entity, %Server.ID{} = server_id, tunnel) do
    with {true, %{server: server}} <- server_exists?(server_id) do
      has_access?(entity, server, tunnel)
    end
  end

  def has_access?(%Entity{} = entity, %Server{} = server, nil) do
    with {true, _} <- belongs_to_entity?(server, entity) do
      %{
        gateway: server,
        endpoint: nil,
        target: server,
        tunnel: nil,
        entity: entity,
        access_type: :local
      }
      |> Henforcer.success()
    end
  end

  def has_access?(%Entity{} = entity, %Server{} = server, %Tunnel{} = tunnel) do
    with true <- tunnel.status == :open || :invalid_tunnel,
         {true, %{server: endpoint}} <- Henforcers.Network.nip_exists?(tunnel.target_nip),
         {true, %{server: gateway}} <- Henforcers.Network.nip_exists?(tunnel.source_nip),
         true <- endpoint.id == server.id || :invalid_tunnel,
         true <- gateway.entity_id == entity.id || :invalid_tunnel do
      %{
        gateway: gateway,
        endpoint: endpoint,
        target: endpoint,
        tunnel: tunnel,
        entity: entity,
        access_type: :remote
      }
      |> Henforcer.success()
    else
      :invalid_tunnel ->
        # The provided tunnel is closed, belongs to someone else or targets a different endpoint
        Henforcer.fail({:tunnel, :not_found})

      {false, _, _} = upstream_error ->
        upstream_error
    end
  end
end
