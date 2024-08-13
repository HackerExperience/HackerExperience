defmodule Webserver.Config do
  def list_webservers do
    Application.get_env(:helix, :webserver)
    |> Keyword.fetch!(:webservers)
  end

  def get_webserver_config(webserver) do
    config =
      Application.get_env(:helix, webserver)
      |> Map.new()

    default_opts =
      %{
        webserver: webserver,
        routes: get_webserver_routes(webserver),
        belts: get_webserver_belts(webserver),
        dispatch_table: get_webserver_dispatch_table(webserver),
        hooks_module: Module.concat([webserver, Hooks])
      }

    Map.merge(default_opts, config)
  end

  def get_webserver_routes(webserver) do
    apply(webserver, :routes, [])
    |> Enum.map(fn {route, opts} ->
      {route, Webserver.Dispatcher, Map.put(opts, :webserver, webserver)}
    end)
  end

  def get_webserver_belts(webserver), do: apply(webserver, :belts, [])

  def get_webserver_dispatch_table(webserver) do
    webserver
    |> to_string()
    |> Kernel.<>(".DispatchTable")
    |> String.to_atom()
  end
end
