defmodule Game.Henforcers.Server do
  alias Core.Henforcer
  alias Game.Services, as: Svc
  alias Game.Henforcers
  alias Game.{Entity, Server}

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
end
