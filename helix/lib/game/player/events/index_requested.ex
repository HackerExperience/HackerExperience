defmodule Game.Events.Player.IndexRequested do
  use Core.Event

  defstruct [:player_id]

  def new(player_id) do
    %__MODULE__{player_id: player_id}
    |> Event.new()
  end

  def handlers(_data, _event) do
    [Game.Handlers.Player]
  end

  defmodule Publishable do
    use Core.Event.Publishable

    def generate_payload(_ev) do
      {:ok, %{foo: "bar"}}
    end

    def whom_to_publish(%{data: %{player_id: player_id}}) do
      %{player: player_id}
    end
  end
end
