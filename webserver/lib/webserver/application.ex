defmodule Webserver.Application do
  @moduledoc false
  use Application

  @dispatch_table :webserver_dispatch

  def start(_type, _args) do
    children = [
      webserver_spec()
    ]

    Logger.add_translator({Webserver.RanchTranslator, :translate})

    opts = [strategy: :one_for_one, name: Webserver.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Use this function when you need to recompile the Webserver routes in runtime.
  """
  def recompile do
    routes =
      Application.get_env(:webserver, :routes, [])
      |> Enum.map(fn {route, opts} -> {route, Webserver.Dispatcher, opts} end)

    dispatch = :cowboy_router.compile([{:_, routes}])
    :persistent_term.put(@dispatch_table, dispatch)
  end

  defp webserver_spec do
    # TODO: DRY routes (also used in `recompile/0` above)
    routes =
      Application.get_env(:webserver, :routes, [])
      |> Enum.map(fn {route, opts} -> {route, Webserver.Dispatcher, opts} end)

    dispatch = :cowboy_router.compile([{:_, routes}])
    :persistent_term.put(@dispatch_table, dispatch)

    # TODO: Move these hard-coded values to a config
    # 4001 if test, via config (TODO)
    port = 4000

    # TODO: Move these hard-coded values to a config
    %{
      id: :server,
      start: {
        :cowboy,
        :start_clear,
        [
          :server,
          %{
            socket_opts: [port: port],
            max_connections: 16_384,
            num_acceptors: 16
          },
          %{env: %{dispatch: {:persistent_term, @dispatch_table}}}
        ]
      },
      restart: :permanent,
      shutdown: :infinity,
      type: :supervisor
    }
  end
end
