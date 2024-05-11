defmodule Core.GraphQL.Endpoint do
  use Webserver.Endpoint

  def get_params(request, unsafe, _session) do
    params = %{
      query: unsafe["query"],
      variables: unsafe["variables"] || []
    }

    {:ok, %{request | params: params}}
  end

  def get_context(request, _, _) do
    {:ok, %{request | context: %{}}}
  end

  def handle_request(request, params, _, _) do
    {:ok, %{request | result: %{gql_result: %{}}}}
  end

  def render_response(request, %{gql_result: r}, _) do
    {:ok, %{request | response: {200, %{gql_result: r}}}}
  end
end
