defmodule Game.Henforcers.Network do
  alias Core.{Henforcer, NIP}
  alias Game.Henforcers
  alias Game.Services, as: Svc

  @type nip_exists_relay :: Henforcers.Server.server_exists_relay()
  @type nip_exists_error :: {false, {:nip, :not_found}, %{}}

  @spec nip_exists?(nip :: term()) ::
          {true, nip_exists_relay}
          | nip_exists_error
  def nip_exists?(%NIP{} = nip) do
    case Svc.Network.fetch(network_connection_by_nip: nip) do
      %_{server_id: server_id} ->
        server_id
        |> Henforcers.Server.server_exists?()
        |> Henforcer.henforce_else({:nip, :not_foundd})

      nil ->
        Henforcer.fail({:nip, :not_found})
    end
  end
end
