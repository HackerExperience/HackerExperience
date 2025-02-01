defmodule Webserver.Hooks do
  alias Webserver.Config

  @callback on_input_validated(req :: any, req_identifier :: any) :: any
  @callback on_get_params_ok(req :: any, req_identifier :: any) :: any
  @callback on_handle_request_ok(req :: any, req_identifier :: any) :: any
  @optional_callbacks on_input_validated: 2, on_get_params_ok: 2, on_handle_request_ok: 2

  def maybe_invoke(name, webserver, args, default_return) do
    hooks_module = Config.get_webserver_config(webserver).hooks_module

    if function_exported?(hooks_module, name, length(args)) do
      apply(hooks_module, name, args)
    else
      default_return
    end
  end

  def on_input_validated(req),
    do: maybe_invoke(:on_input_validated, req.webserver, [req, build_identifier(req)], {:ok, req})

  def on_get_params_ok(req),
    do: maybe_invoke(:on_get_params_ok, req.webserver, [req, build_identifier(req)], {:ok, req})

  def on_handle_request_ok(req),
    do: maybe_invoke(:on_handle_request_ok, req.webserver, [req, build_identifier(req)], {:ok, req})

  defp build_identifier(%{cowboy_request: %{path: path, method: method}, endpoint: endpoint}),
    do: {endpoint, path, method}
end
