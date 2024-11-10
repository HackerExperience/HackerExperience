defmodule Game.Henforcers.Server do
  alias Core.Henforcer
  alias Game.Services, as: Svc
  alias Game.Server

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
end
