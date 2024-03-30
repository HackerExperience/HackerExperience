defmodule DB.Schema.List do
  @moduledoc """
  This module is generated automatically via `mix db.schema.list`.

  It is used by DB.Boot to load all existing tables and verify their
  SQLite schemas match the schemas defined in the codebase.
  """

  @modules [
    {:lobby, Lobby.User},
    {:test, Sample.Friend},
    {:test, Sample.Post}
  ]

  @doc """
  Returns a list of all the schemas defined in the codebase.
  """
  def all, do: @modules
end
