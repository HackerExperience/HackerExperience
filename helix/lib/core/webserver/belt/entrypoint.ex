defmodule Core.Webserver.Belt.Entrypoint do
  @moduledoc """
  The very first belt executed in the LobbyAPI and GameAPI. Attributions include:

  ### Specifying the `universe`

  The `universe` informs the context in which a given request belongs to. Values are one of:
  - :lobby
  - :singleplayer
  - :multiplayer

  This will be used mainly to determine which database a request should initially connect to.
  """

  use Webserver.Conveyor.Belt

  def call(request, _, opts) do
    request
    |> put_universe(opts)
  end

  defp put_universe(request, opts) do
    universe = Keyword.fetch!(opts, :universe)

    %{request | universe: get_universe!(opts)}
  end

  defp get_universe!(opts) do
    case Keyword.get(opts, :universe) do
      :lobby ->
        :lobby

      {:game, env} when env in [:singleplayer, :multiplayer] ->
        env

      e ->
        raise "Missing or invalid `universe` opt in #{__MODULE__} (#{inspect(e)})"
    end
  end
end
