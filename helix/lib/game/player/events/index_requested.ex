defmodule Game.Events.Player.IndexRequested do
  use Core.Event
  alias Game.Index
  alias Game.Services, as: Svc

  defstruct [:player_id]

  @name :index_requested

  def new(player_id) do
    %__MODULE__{player_id: player_id}
    |> Event.new()
  end

  def handlers(_, _), do: []

  defmodule Publishable do
    use Core.Event.Publishable

    def spec do
      selection(
        schema(%{
          player: Index.Player.output_spec()
        }),
        [:player]
      )
    end

    def generate_payload(%{data: %{player_id: player_id}}) do
      # TODO: DB context should be automatically handled by Core.Event (and the default behavior can
      # be overriden by the specific event implementation). Similar to how it works with Endpoints.
      # Core.with_context(:universe, :read, fn ->
      player = Svc.Player.fetch!(by_id: player_id)

      payload =
        %{
          player: Index.Player.index(player)
        }

      {:ok, payload}
      # end)
    end

    def whom_to_publish(%{data: %{player_id: player_id}}) do
      %{player: player_id}
    end
  end
end
