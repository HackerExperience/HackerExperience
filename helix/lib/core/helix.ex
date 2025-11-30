defmodule Helix do
  @type role ::
          :lobby | :singleplayer | :multiplayer | :all

  @doc """
  Returns the role assigned to this Helix node. It can be one of:
  - lobby: Only runs the Lobby service.
  - singleplayer: Only runs the Singleplayer service.
  - multiplayer: Only runs the Multiplayer service.
  - all: Runs all services in a single application.
  """
  @spec get_role() ::
          role
  def get_role,
    do: Application.fetch_env!(:helix, :role)
end
