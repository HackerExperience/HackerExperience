defmodule Webserver.OpenApi.Spec.GeneratorTest do
  use ExUnit.Case, async: true

  alias Webserver.OpenApi.Spec.Generator

  describe "generate/1 for the Lobby spec" do
    setup do
      {:ok, %{spec: Lobby.Webserver.spec()}}
    end

    test "generates expected `openapi`", %{spec: spec} do
      assert %{openapi: openapi_version} = Generator.generate(spec)
      assert openapi_version == "3.1.0"
    end

    test "generates expected `info`", %{spec: spec} do
      assert %{info: info} = Generator.generate(spec)
      assert info.title == spec.title
      assert info.version == spec.version
      assert info.description == spec[:description] || spec.title
    end

    # We can't test exhaustively every path. Focusing on basic coverage + edge cases
    test "generates expected `paths`", %{spec: spec} do
      assert %{paths: paths} = Generator.generate(spec)

      # Correctly generates /v1/user/login path entry
      assert %{post: user_login} = paths["/v1/user/login"]
      assert user_login.operationId == "UserLogin"
      assert user_login.requestBody["$ref"] =~ "requestBodies/UserLoginRequest"
      assert user_login.responses["200"]["$ref"] =~ "responses/UserLoginOkResponse"
      assert user_login.responses["400"]["$ref"] =~ "responses/GenericBadRequestResponse"
      assert user_login.responses["401"]["$ref"] =~ "responses/GenericUnauthorizedResponse"
      assert user_login.responses["422"]["$ref"] =~ "responses/GenericErrorResponse"
    end

    # We can't test exhaustively every request body. Focusing on basic coverage + edge cases
    test "generates expected `components` (requestBodies)", %{spec: spec} do
      assert %{components: %{requestBodies: request_bodies}} = Generator.generate(spec)

      # It includes request bodies from endpoints
      login_request_body = Map.fetch!(request_bodies, "UserLoginRequest")
      assert login_request_body.description == "TODO description"
      assert login_request_body.required == true
      assert %{"application/json" => %{schema: schema}} = login_request_body.content
      assert schema["$ref"] == "#/components/schemas/UserLoginInput"
    end

    # We can't test exhaustively every response. Focusing on basic coverage + edge cases
    test "generates expected `components` (responses)", %{spec: spec} do
      assert %{components: %{responses: responses}} = Generator.generate(spec)

      # It includes responses from endpoints
      register_response = Map.fetch!(responses, "UserRegisterOkResponse")
      assert register_response.description == "TODO description"
      assert %{"application/json" => %{schema: schema}} = register_response.content
      assert schema.type == :object
      assert schema.required == [:data]
      assert schema.properties.data["$ref"] == "#/components/schemas/UserRegisterOutput"

      # It includes default responses defined at the Helix Spec
      generic_error_response = Map.fetch!(responses, "GenericErrorResponse")
      assert generic_error_response == spec.default_responses["GenericErrorResponse"]
    end

    # We can't test exhaustively every schema. Focusing on basic coverage + edge cases
    test "generates expected `components` (schemas)", %{spec: spec} do
      assert %{components: %{schemas: schemas}} = Generator.generate(spec)

      # It includes input schemas from an endpoint
      user_login_input = Map.fetch!(schemas, "UserLoginInput")
      assert user_login_input.type == :object
      assert user_login_input.required == ["password", "email"]
      assert user_login_input.properties["email"] == %{type: :string}
      assert user_login_input.properties["password"] == %{type: :string}

      # It includes output schemas from an endpoint
      user_login_output = Map.fetch!(schemas, "UserLoginOutput")
      assert user_login_output.type == :object
      assert user_login_output.required == [:token]
      assert user_login_output.properties[:token] == %{type: :string}

      # It includes default schemas defined at the Helix Spec
      generic_error = Map.fetch!(schemas, "GenericError")
      assert generic_error.type == :object
      assert generic_error.required == [:msg]
      assert generic_error.properties[:msg] == %{type: :string}
    end
  end

  describe "generate/1 for the Game spec" do
    setup do
      {:ok, %{spec: Game.Webserver.spec()}}
    end

    test "generates expected `paths` (with path parameters)", %{spec: spec} do
      %{paths: paths, components: %{schemas: schemas}} = Generator.generate(spec)

      # We'll be using the ServerLogin endpoint for this test
      assert %{post: server_login} = paths["/v1/server/{nip}/login/{target_nip}"]

      # It has two path parameters: nip and target_nip
      assert Enum.count(server_login.parameters) == 2
      assert nip_param = Enum.find(server_login.parameters, &(&1.name == "nip"))
      assert target_nip_param = Enum.find(server_login.parameters, &(&1.name == "target_nip"))

      assert nip_param.name == "nip"
      assert nip_param.in == :path
      assert nip_param.required
      assert nip_param.schema.type == :string

      assert target_nip_param.name == "target_nip"
      assert target_nip_param.in == :path
      assert target_nip_param.required
      assert target_nip_param.schema.type == :string

      # The ServerLoginInput schema (body of the request) filtered out path parameters
      assert server_login_input = schemas["ServerLoginInput"]

      # `nip` and `target_nip` are not properties of the body payload
      refute server_login_input.properties["nip"]
      refute server_login_input.properties["target_nip"]

      # `tunnel_id`, for example, is
      assert server_login_input.properties["tunnel_id"]

      # Similarly, `nip` and `target_nip` are not required properties of the body
      refute "nip" in server_login_input.required
      refute "target_nip" in server_login_input.required
    end

    test "requires authorization header on non-public endpoints", %{spec: spec} do
      %{paths: paths, components: %{securitySchemes: security_schemes}} = Generator.generate(spec)

      # ServerLogin is an endpoint that requires Authorization header to be present
      assert %{post: server_login} = paths["/v1/server/{nip}/login/{target_nip}"]
      assert server_login.security == [%{"AuthorizationToken" => []}]

      # The "AuthorizationToken" scheme is defined in `security_schemes`
      assert token_scheme = security_schemes["AuthorizationToken"]
      assert token_scheme.in == :header
      assert token_scheme.type == "apiKey"
      assert token_scheme.name == "Authorization"

      # On the other hand, the PlayerSync endpoint does not require such header
      assert %{post: player_sync} = paths["/v1/player/sync"]
      refute Map.has_key?(player_sync, :security)
    end
  end

  describe "generate/1 for the Events spec" do
    setup do
      spec = Core.Event.Publishable.Spec.spec()
      {:ok, %{spec: spec}}
    end

    test "includes the event schemas", %{spec: spec} do
      assert %{components: %{schemas: schemas}} = Generator.generate(spec)

      # Grab a few random schemas and make sure they have the correct definition
      index_requested = Map.fetch!(schemas, "index_requested")

      assert index_requested.type == :object
      assert index_requested.required == [:software, :player]
      assert index_requested.properties[:player] == %{"$ref" => "#/components/schemas/IdxPlayer"}
      assert index_requested.properties[:software]["$ref"] == "#/components/schemas/IdxSoftware"

      # Supports the Enum type
      tunnel_created = Map.fetch!(schemas, "tunnel_created")
      assert tunnel_created.properties.access.type == :string
      assert tunnel_created.properties.access.enum == Game.Tunnel.access_types()
    end
  end

  describe "generate/1 for the Processes spec" do
    setup do
      spec = Game.Process.Viewable.Spec.spec()
      {:ok, %{spec: spec}}
    end

    test "includes the process schemas", %{spec: spec} do
      assert %{components: %{schemas: schemas}} = Generator.generate(spec)

      # Grab a few random schemas and make sure they have the correct definition
      log_delete = Map.fetch!(schemas, "log_delete")

      assert log_delete.type == :object
      assert log_delete.required == [:log_id]
      assert log_delete.properties[:log_id] == %{type: :string}
    end
  end

  describe "normalize_helix_spec/1" do
    test "normalizes the endpoint id" do
      endpoint_1 = test_spec_endpoint()
      endpoint_2 = test_spec_endpoint(method: :get, xattrs: %{id: "CustomID"})
      spec = test_spec(endpoints: [endpoint_1, endpoint_2] |> Map.new())

      %{endpoints: endpoints} = Generator.normalize_helix_spec(spec)

      # One of the endpoits had the ID inferred, whereas the other kept the custom value
      assert Enum.find(endpoints, fn {_, %{id: id}} -> id == "UserLogin" end)
      assert Enum.find(endpoints, fn {_, %{id: id}} -> id == "CustomID" end)
    end

    test "normalizes the request body" do
      endpoint_1 = test_spec_endpoint()
      endpoint_2 = test_spec_endpoint(method: :get, xattrs: %{request_body: "FooRequest"})
      spec = test_spec(endpoints: [endpoint_1, endpoint_2] |> Map.new())

      %{endpoints: endpoints} = Generator.normalize_helix_spec(spec)

      # One of the endpoits has the default request name, the other has the custom value
      assert Enum.find(endpoints, fn {_, %{request_body: req}} -> req == "UserLoginRequest" end)
      assert Enum.find(endpoints, fn {_, %{request_body: req}} -> req == "FooRequest" end)
    end

    test "normalizes the responses" do
      endpoint_1 = test_spec_endpoint(method: :post, responses: [{200, "CustomOkResponse"}, 400])
      endpoint_2 = test_spec_endpoint(method: :get, responses: [200, {401, "CustomErrorResponse"}])
      spec = test_spec(endpoints: [endpoint_1, endpoint_2] |> Map.new())

      %{endpoints: endpoints} = Generator.normalize_helix_spec(spec)

      {_, %{responses: responses_1}} =
        Enum.find(endpoints, fn {{_, method}, _} -> method == :post end)

      assert responses_1[200] == "CustomOkResponse"
      assert responses_1[400] == "GenericBadRequestResponse"

      {_, %{responses: responses_2}} =
        Enum.find(endpoints, fn {{_, method}, _} -> method == :get end)

      assert responses_2[200] == "UserLoginOkResponse"
      assert responses_2[401] == "CustomErrorResponse"
    end
  end

  defp test_spec(opts) do
    endpoints = Map.new([test_spec_endpoint()])

    %{
      type: :webserver_request,
      title: Keyword.get(opts, :title, "TestAPI"),
      version: Keyword.get(opts, :version, "1.0.0"),
      endpoints: Keyword.get(opts, :endpoints, endpoints),
      default_responses: Keyword.get(opts, :default_responses, %{}),
      default_schemas: Keyword.get(opts, :default_schemas, %{})
    }
  end

  defp test_spec_endpoint(opts \\ []) do
    {
      {
        Keyword.get(opts, :endpoint, Lobby.Endpoint.User.Login),
        Keyword.get(opts, :method, :post)
      },
      %{
        path: Keyword.get(opts, :path, "/v1/user/login"),
        responses: Keyword.get(opts, :responses, [200])
      }
      |> Map.merge(opts[:xattrs] || %{})
    }
  end
end
