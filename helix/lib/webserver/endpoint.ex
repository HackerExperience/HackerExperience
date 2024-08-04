defmodule Webserver.Endpoint do
  require Logger
  alias HELL.Utils
  alias Webserver.Conveyor

  defmacro __using__(_) do
    quote do
      # No-op for now
    end
  end

  def validate_input(%{endpoint: endpoint} = request, raw_params) do
    case Norm.conform(raw_params, endpoint.input_spec()) do
      {:ok, parsed_params} ->
        {:ok, %{request | parsed_params: Utils.Map.safe_atomify_keys(parsed_params)}}

      {:error, reason} ->
        # TODO: Proper formatting of error
        {:error, %{request | response: {400, "missing_or_invalid_input: #{inspect(reason)}"}}}
    end
  end

  def render_response(%{conveyor: conveyor, response: response} = request) do
    {status_code, response_payload} = parse_response(response)

    conveyor =
      conveyor
      |> Conveyor.set_message(response_payload)
      |> Conveyor.set_status(status_code)

    %{request | conveyor: conveyor}
  end

  defp parse_response({code, {a, b}}) when code >= 400 do
    {code, %{error: "#{a}_#{b}"}}
  end

  defp parse_response({code, error}) when code >= 400 do
    {code, %{error: error}}
  end

  defp parse_response({code, %{gql_result: data}})
       when code >= 200 and code < 300 do
    {code, data}
  end

  defp parse_response({code, data}) when code >= 200 and code < 300 do
    {code, %{data: data}}
  end

  defp parse_response(code) when code >= 200 and code < 300 do
    {code, %{data: nil}}
  end

  defp parse_response(code) when code >= 500 do
    {code, %{error: "internal_server_error"}}
  end

  defp parse_response(response) do
    Logger.error("Unknown response from handler: #{inspect(response)}")
    {503, %{error: "invalid_handler_response"}}
  end
end
