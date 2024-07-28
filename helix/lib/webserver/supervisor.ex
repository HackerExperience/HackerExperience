defmodule Webserver.Supervisor do
  @moduledoc false
  use Supervisor
  alias Webserver.Config

  @env Mix.env()

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children =
      Config.list_webservers()
      |> Enum.map(&Config.get_webserver_config/1)
      |> Enum.map(&webserver_spec/1)

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

    %{
      id: config.webserver,
      start: {
        :cowboy,
        :start_clear,
        [
          :server,
          %{
            socket_opts: [port: config.port],
            # TODO: Move these hard-coded values to a config
            max_connections: 16_384,
            num_acceptors: 16
          },
          %{env: %{dispatch: {:persistent_term, config.dispatch_table}}}
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