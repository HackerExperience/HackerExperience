defmodule Webserver.Routes do
  @doc """
  Available routes in the API.
  """
  def routes do
    [
      {:post, "/user/register", Lobby.Endpoint.User.Register}
    ]
    |> transform_routes("/v1")
  end

  @doc """
  Use this function when you need to recompile the routes during runtime.
  """
  def recompile do
    dispatch = :cowboy_router.compile([{:_, routes()}])
    :persistent_term.put(:mob_dispatch, dispatch)
  end

  defp transform_routes(routes, prefix) do
    Enum.map(routes, fn
      {method, path, handler} ->
        args = %{handler: handler, method: method}
        {prefix <> path, Webserver.Dispatcher, args}
    end)
  end
end
