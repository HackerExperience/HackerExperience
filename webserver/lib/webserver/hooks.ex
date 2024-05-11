defmodule Webserver.Hooks do
  @hooks_module Application.compile_env(:webserver, :hooks)

  @callback on_get_params_ok(req :: any, req_identifier :: any) :: any
  @callback on_handle_request_ok(req :: any, req_identifier :: any) :: any
  @optional_callbacks on_get_params_ok: 2, on_handle_request_ok: 2

  def maybe_invoke(name, args, default_return) do
    # TODO: This is needed for now, but figure out a way to have the callback module be
    # loaded. Maybe use it somewhere in the application, or do a no-op boot hook.
    # We don't want to load it all the time in the critical path.
    # Alternatively, ensure loaded on Webserver startup via a one-off Boot task
    Code.ensure_loaded(@hooks_module)

    if function_exported?(@hooks_module, name, length(args)) do
      apply(@hooks_module, name, args)
    else
      default_return
    end
  end

  def on_get_params_ok(req),
    do: maybe_invoke(:on_get_params_ok, [req, build_identifier(req)], {:ok, req})

  def on_handle_request_ok(req),
    do: maybe_invoke(:on_handle_request_ok, [req, build_identifier(req)], {:ok, req})

  defp build_identifier(%{cowboy_request: %{path: path, method: method}, endpoint: endpoint}),
    do: {endpoint, path, method}
end
