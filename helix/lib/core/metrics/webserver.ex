defmodule Core.Metrics.Webserver do
  alias Webserver.Request

  def setup do
    Hotel.Metrics.define_sum("http.server.request_count")
  end

  def count_http_request(%Request{} = request) do
    status = request.conveyor.response_status
    endpoint = request.endpoint_str

    Hotel.Metrics.inc("http.server.request_count", %{endpoint: endpoint, status: status})
  end
end
