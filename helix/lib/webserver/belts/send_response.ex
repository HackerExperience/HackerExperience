defmodule Webserver.Belt.SendResponse do
  use Webserver.Conveyor.Belt

  def call(%{cowboy_request: cowboy_request} = request, conveyor, _) do
    body = conveyor.response_message |> :json.encode()

    cowboy_request = :cowboy_req.reply(conveyor.response_status, %{}, body, cowboy_request)

    %{request | cowboy_request: cowboy_request}
  end
end
