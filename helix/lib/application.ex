defmodule Helix.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DB.Supervisor, name: DB.Supervisor},
      webserver_spec()
    ]

    Logger.add_translator({Webserver.RanchTranslator, :translate})

    opts = [strategy: :one_for_one, name: Helix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp webserver_spec do
    dispatch = :cowboy_router.compile([{:_, Webserver.Routes.routes()}])
    :persistent_term.put(:helix_dispatch, dispatch)

    # TODO: Move these hard-coded values to a config
    port = if @env == :test, do: 4001, else: 4000

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
          %{env: %{dispatch: {:persistent_term, :helix_dispatch}}}
        ]
      },
      restart: :permanent,
      shutdown: :infinity,
      type: :supervisor
    }
  end
end
