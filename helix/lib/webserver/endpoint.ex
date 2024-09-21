defmodule Webserver.Endpoint do
  use Norm
  import Core.Spec
  require Logger
  alias Webserver.Conveyor

  def validate_input(request, endpoint, raw_params) do
    case Norm.conform(raw_params, endpoint.input_spec()) do
      {:ok, parsed_params} ->
        {:ok, %{request | parsed_params: Renatils.Map.safe_atomify_keys(parsed_params)}}

      {:error, spec_error} ->
        # TODO: Proper formatting of error
        error_response =
          %{
            msg: "invalid_input",
            details: format_spec_error(spec_error)
          }

        {:error, %{request | response: {400, error_response}}}
    end
  end

  def render_response(%{conveyor: conveyor, response: response} = request, endpoint) do
    {status_code, response_payload} = parse_response(response)

    # TODO: Add `metadata` entry (as sibling of `data`)
    # TODO: Include the `request_id` and `x_request_id` in a metadata entry

    # Ensures that the outgoing message adheres to the API contract
    enforce_output_spec!(endpoint, status_code, response_payload)

    conveyor =
      conveyor
      |> Conveyor.set_message(response_payload)
      |> Conveyor.set_status(status_code)

    %{request | conveyor: conveyor}
  end

  defp enforce_output_spec!(endpoint, code, %{data: response}) when code >= 200 and code < 300 do
    # For successful responses we expect the endpoint to explicitly implement the `output_spec`.
    Norm.conform!(response, endpoint.output_spec(code))
  end

  defp enforce_output_spec!(endpoint, error_code, %{error: error}) do
    # Error responses may not necessarily be defined by the endpoint, in which case we fallback to
    # the default error spec for the corresponding `error_code`.
    error_spec =
      try do
        endpoint.output_spec(error_code)
      rescue
        FunctionClauseError ->
          output_spec_for_error(error_code)
      end

    Norm.conform!(error, error_spec)
  end

  defp parse_response({code, {a, b}}) when code >= 400,
    do: {code, %{error: %{msg: "#{a}_#{b}"}}}

  defp parse_response({code, error}) when code >= 400 and is_map(error),
    do: {code, %{error: error}}

  defp parse_response({code, error_msg}) when code >= 400,
    do: {code, %{error: %{msg: "#{error_msg}"}}}

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
    {code, %{error: %{msg: "internal_server_error"}}}
  end

  defp parse_response(response) do
    Logger.error("Unknown response from handler: #{inspect(response)}")
    {503, %{error: %{msg: "invalid_handler_response"}}}
  end

  defp output_spec_for_error(_) do
    selection(
      schema(%{
        msg: binary(),
        details: binary()
      }),
      [:msg]
    )
  end

  defp format_spec_error(spec_error) do
    # Return the entire spec error except for the input (which may contain sensitive/PII data)
    spec_error
    |> Enum.map(fn error -> Map.drop(error, [:input]) end)
    |> Kernel.inspect()
  end
end
