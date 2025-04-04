defmodule Webserver.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger
  alias Webserver.Config

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children =
      Config.list_webservers()
      |> Enum.map(&Config.get_webserver_config/1)
      |> Enum.map(&webserver_spec/1)

    # Block webserver from starting until all Helix modules are loaded
    Helix.Application.wait_until_helix_modules_are_loaded()
    Logger.info("Webservers started")

    Logger.add_translator({Webserver.RanchTranslator, :translate})
    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Use this function when you need to recompile the Webserver routes in runtime.
  """
  def recompile do
    Config.list_webservers()
    |> Enum.map(&Config.get_webserver_config/1)
    |> Enum.each(&create_dispatch_table/1)
  end

  defp webserver_spec(config) do
    create_dispatch_table(config)

    # TODO: Confirm HTTP2 support in curl + browser
    %{
      id: config.webserver,
      start: {
        :cowboy,
        :start_clear,
        [
          config.webserver,
          %{
            socket_opts: [port: config.port],
            # TODO: Move these hard-coded values to a config
            max_connections: 16_384,
            num_acceptors: 16
          },
          %{
            env: %{dispatch: {:persistent_term, config.dispatch_table}},
            # We need an infinite idle timeout for SSE support.
            idle_timeout: :infinity,
            # If the SSE connection does not push a single event in `inactivity_timeout` ms, close
            # it. We send pings every 60s. If it reached 150s of inactivity, something is wrong.
            inactivity_timeout: 150_000
          }
        ]
      },
      restart: :permanent,
      shutdown: :infinity,
      type: :supervisor
    }
  end

  defp create_dispatch_table(config) do
    dispatch = :cowboy_router.compile([{:_, config.routes}])
    :persistent_term.put(config.dispatch_table, dispatch)
  end
end
