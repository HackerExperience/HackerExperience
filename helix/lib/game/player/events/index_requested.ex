defmodule Game.Events.Player.IndexRequested do
  use Core.Event.Definition
  alias Game.Index
  alias Game.Services, as: Svc

  defstruct [:player_id]

  @type t :: term

  @name :index_requested

  def new(player_id) do
    %__MODULE__{player_id: player_id}
    |> Event.new()
  end

  defmodule Publishable do
    use Core.Event.Publishable.Definition

    def spec do
      selection(
        schema(%{
          player: Index.Player.output_spec()
        }),
        [:player]
      )
    end

    def generate_payload(%{data: %{player_id: player_id}}) do
      player = Svc.Player.fetch!(by_id: player_id)

      payload =
        %{
          player: player |> Index.Player.index() |> Index.Player.render_index()
        }

      {:ok, payload}
    end

    def whom_to_publish(%{data: %{player_id: player_id}}),
      do: %{player: player_id}
  end
end
