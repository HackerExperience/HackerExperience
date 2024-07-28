defmodule Webserver.Config do
  def list_webservers do
    Application.get_env(:helix, :webserver)
    |> Keyword.fetch!(:webservers)
  end

  def get_webserver_config(webserver) do
    Application.get_env(:helix, webserver)
    |> Map.new()
    |> Map.merge(%{
      webserver: webserver,
      routes: get_webserver_routes(webserver),
      belts: get_webserver_belts(webserver),
      dispatch_table: get_webserver_dispatch_table(webserver)
    })
  end

  def get_webserver_routes(webserver) do
    apply(webserver, :routes, [])
    |> Enum.map(fn {route, opts} ->
      {route, Webserver.Dispatcher, Map.put(opts, :webserver, webserver)}
    end)
  end

  def get_webserver_belts(webserver), do: apply(webserver, :belts, [])

  def get_webserver_hooks(webserver), do: Module.concat([webserver, Hooks])

  def get_webserver_dispatch_table(webserver) do
    webserver
    |> to_string()
    |> Kernel.<>(".DispatchTable")
    |> String.to_atom()
  end
end
