defmodule Game.Services.Installation do
  alias Feeb.DB
  alias Game.{Installation, Server}

  @doc """
  Fetches an Installation matching the given filters.
  """
  @spec fetch(Server.id(), list, list) ::
          Installation.t() | nil
  def fetch(%Server.ID{} = server_id, filter_params, opts \\ []) do
    filters = [
      by_id: {:one, {:installations, :fetch}}
    ]

    Core.with_context(:server, server_id, :read, fn ->
      Core.Fetch.query(filter_params, opts, filters)
    end)
  end

  def uninstall(%Installation{} = installation) do
    DB.delete(installation)
  end
end
