defmodule Webserver.Supervisor do
  @moduledoc false
  use Supervisor

  @env Mix.env()
  @dispatch_table :webserver_dispatch

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      webserver_spec()
    ]

    Logger.add_translator({Webserver.RanchTranslator, :translate})
    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Use this function when you need to recompile the Webserver routes in runtime.
  """
  def recompile do
    routes =
      Application.get_env(:helix, :webserver, routes: [])
      |> Map.new()
      |> Map.fetch!(:routes)
      |> Enum.map(fn {route, opts} -> {route, Webserver.Dispatcher, opts} end)

    dispatch = :cowboy_router.compile([{:_, routes}])
    :persistent_term.put(@dispatch_table, dispatch)
  end

  defp webserver_spec do
    # TODO: DRY routes (also used in `recompile/0` above)
    routes =
      Application.get_env(:helix, :webserver, [])
      |> Map.new()
      |> Map.fetch!(:routes)
      |> Enum.map(fn {route, opts} -> {route, Webserver.Dispatcher, opts} end)

    dispatch = :cowboy_router.compile([{:_, routes}])
    :persistent_term.put(@dispatch_table, dispatch)

    # TODO: Move these hard-coded values to a config
    # 4001 if test, via config (TODO)
    # TODO: Consider port use-case when supporting multiple webservers
    port =
      if @env == :test do
        4001
      else
        4000
      end

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
