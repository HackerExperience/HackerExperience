defmodule Webserver.Endpoint do
  require Logger

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [cast: 3]
    end
  end

  def cast(model, field, raw_v, opts \\ []) do
    opts = Keyword.put_new(opts, :cast, true)
    validator_module = Module.concat(model, Validator)

    result =
      try do
        apply(validator_module, field, [raw_v, opts])
      rescue
        FunctionClauseError ->
          if is_nil(raw_v), do: {:error, :missing_input}, else: :error
      end

    case result do
      {:ok, v} -> {:ok, v}
      {:error, r} -> {:error, {field, r}}
      :error -> {:error, {field, :invalid_input}}
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
