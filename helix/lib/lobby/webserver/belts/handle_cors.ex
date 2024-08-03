defmodule Lobby.Webserver.Belt.HandleCors do
  def call(%{cowboy_request: req} = request, conveyor, _opts) do
    # TODO: For now we are accepting everything
    # TODO: Move application/json resp header elsewhere (unrelated to CORS)
    req = :cowboy_req.set_resp_header("content-type", "application/json", req)
    req = :cowboy_req.set_resp_header("Access-Control-Allow-Origin", "*", req)
    req = :cowboy_req.set_resp_header("Access-Control-Allow-Credentials", "true", req)

    req =
      :cowboy_req.set_resp_header(
        "Access-Control-Allow-Headers",
        "Authorization,Content-Type",
        req
      )

    req = :cowboy_req.set_resp_header("Vary", "Origin", req)

    if req.method == "OPTIONS" do
      _cowboy_request = :cowboy_req.reply(200, %{}, "", req)
      %{conveyor | halt?: true}
    else
      %{request | cowboy_request: req}
    end
  end
end
