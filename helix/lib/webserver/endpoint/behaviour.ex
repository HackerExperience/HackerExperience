defmodule Webserver.Endpoint.Behaviour do
  # TODO
  @type request :: map()

  # TODO
  @type session :: map()

  @callback input_spec() :: %Norm.Core.Selection{}
  @callback output_spec(response_code :: integer()) :: %Norm.Core.Selection{}

  @callback get_params(request(), parsed :: map(), session()) ::
              {:ok, request} | {:error, request}

  @callback get_context(request(), params :: map(), session()) ::
              {:ok, request} | {:error, request}

  @callback handle_request(request(), params :: map(), context :: map(), session()) ::
              {:ok, request} | {:error, request}

  @callback render_response(request(), data :: map(), session()) ::
              {:ok, request} | {:error, request}
end
