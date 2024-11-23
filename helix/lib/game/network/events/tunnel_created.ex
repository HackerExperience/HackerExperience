defmodule Game.Events.Network.TunnelCreated do
  use Core.Event.Definition
  alias Core.{ID, NIP}
  alias Game.{Player, Tunnel}

  defstruct [:tunnel, :player_id]

  @name :tunnel_created

  def new(%Tunnel{} = tunnel, %Player.ID{} = player_id) do
    %__MODULE__{tunnel: tunnel, player_id: player_id}
    |> Event.new()
  end

  def handlers(_, _), do: []

  defmodule Publishable do
    use Core.Event.Publishable.Definition

    def spec do
      selection(
        schema(%{
          tunnel_id: binary(),
          source_nip: binary(),
          target_nip: binary(),
          # TODO: Is Enum supported? oneOf?
          access: binary()
        }),
        [:tunnel_id, :source_nip, :target_nip, :access]
      )
    end

    def generate_payload(%{data: %{tunnel: tunnel}}) do
      payload =
        %{
          tunnel_id: tunnel.id |> ID.to_external(),
          source_nip: NIP.to_external(tunnel.source_nip),
          target_nip: NIP.to_external(tunnel.target_nip),
          access: "#{tunnel.access}"
        }

      {:ok, payload}
    end

    def whom_to_publish(%{data: %{player_id: player_id}}),
      do: %{player: player_id}
  end
end
