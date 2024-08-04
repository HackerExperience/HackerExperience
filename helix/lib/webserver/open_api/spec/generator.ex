defmodule Webserver.OpenApi.Spec.Generator do
  @doc """
  DOCME
  """
  def generate(helix_spec) do
    # TODO: Maybe add step to validate helix spec?
    helix_spec = normalize_helix_spec(helix_spec)

    %{
      openapi: "3.1.0",
      info: generate_info(helix_spec),
      paths: generate_paths(helix_spec),
      components: generate_components(helix_spec)
    }
  end

  defp generate_info(helix_spec) do
    %{
      title: helix_spec.title,
      description: helix_spec[:description],
      version: helix_spec.version
    }
  end

  defp generate_paths(%{endpoints: endpoints}) do
    endpoints
    |> Enum.group_by(fn {_, %{path: path}} -> path end)
    |> Enum.map(fn {path, path_endpoints} ->
      path_definitions =
        Enum.map(path_endpoints, fn {{_endpoint, method}, entry} ->
          endpoint_responses =
            Enum.map(entry.responses, fn {code, response_ref} ->
              {"#{code}", %{"$ref" => "\#/components/responses/#{response_ref}"}}
            end)
            |> Map.new()

          endpoint_definition =
            %{
              operationId: entry.id,
              requestBody: %{
                "$ref" => "\#/components/requestBodies/#{entry.request_body}"
              },
              responses: endpoint_responses
            }

          {method, endpoint_definition}
        end)
        |> Map.new()

      {path, path_definitions}
    end)
    |> Map.new()
  end

  defp generate_components(helix_spec) do
    %{
      schemas: generate_schemas(helix_spec),
      requestBodies: generate_request_bodies(helix_spec),
      responses: generate_responses(helix_spec)
    }
  end

  defp generate_request_bodies(%{endpoints: endpoints}) do
    Enum.map(endpoints, fn {{_endpoint, _method}, entry} ->
      request_body_name = entry.request_body
      input_spec_name = "#{entry.id}Input"

      request_body_schema =
        %{
          schema: %{
            "$ref" => "\#/components/schemas/#{input_spec_name}"
          }
        }

      request_body_content =
        Map.put(%{}, "application/json", request_body_schema)

      request_body =
        %{
          required: true,
          description: "TODO descriptioin",
          content: request_body_content
        }

      {request_body_name, request_body}
    end)
    |> Map.new()
  end

  defp generate_responses(%{endpoints: endpoints, default_responses: default_responses}) do
    Enum.reduce(endpoints, default_responses, fn {{_endpoint, _method}, entry}, acc ->
      responses = Enum.map(entry.responses, fn {_code, name} -> name end)

      Enum.reduce(responses, acc, fn response_name, iacc ->
        if Map.has_key?(iacc, response_name) do
          iacc
        else
          output_spec_name = "#{entry.id}Output"

          response_schema =
            %{
              schema: %{
                type: :object,
                required: [:data],
                properties: %{
                  data: %{
                    "$ref" => "\#/components/schemas/#{output_spec_name}"
                  }
                }
              }
            }

          entry =
            %{
              description: "TODO Description",
              content: Map.put(%{}, "application/json", response_schema)
            }

          Map.put(iacc, response_name, entry)
        end
      end)
    end)
  end

  defp generate_schemas(%{endpoints: endpoints, default_schemas: default_schemas}) do
    Enum.reduce(endpoints, %{}, fn {{endpoint, _method}, entry}, acc ->
      # TODO: DRY name logic (used elsewhere too)
      input_schema_name = "#{entry.id}Input"
      output_schema_name = "#{entry.id}Output"

      input_spec = apply(endpoint, :input_spec, [])
      output_spec = apply(endpoint, :output_spec, [])

      acc = build_schema(input_spec, input_schema_name, acc)
      build_schema(output_spec, output_schema_name, acc)
    end)
    |> Enum.map(fn {schema_name, schema_entries} ->
      {schema_name, schema_definition_to_oas31_format(schema_entries)}
    end)
    |> Map.new()
    |> Map.merge(default_schemas)
  end

  # TODO: Add type for schema definition and oas31 format
  defp schema_definition_to_oas31_format(schema_entries) do
    required_fields =
      Enum.reduce(schema_entries, [], fn {entry, definition}, acc ->
        if definition.required, do: [entry | acc], else: acc
      end)

    properties =
      Enum.reduce(schema_entries, %{}, fn {entry, definition}, acc ->
        property =
          case definition.type do
            {:ref, ref_name} ->
              %{"$ref" => "\#/components/schemas/#{ref_name}"}

            {:array, {:ref, ref_name}} ->
              %{
                type: :array,
                items: %{
                  "$ref" => "\#/components/schemas/#{ref_name}"
                }
              }

            scalar_type ->
              %{type: scalar_type}
          end

        Map.put(acc, entry, property)
      end)

    %{
      type: :object,
      required: required_fields,
      properties: properties
    }
  end

  defp build_schema(%Norm.Core.Selection{required: required, schema: schema}, name, acc) do
    if Map.has_key?(acc, name) do
      # The schema identified by `name` has already been generated, no need to generate it again
      acc
    else
      # Generate the schema identified by `name` and include it in the full schema map
      {schema, schema_refs} = openapi_schema_from_norm_spec(schema, required, name, acc)
      Map.put(schema_refs, name, schema)
    end
  end

  defp openapi_schema_from_norm_spec(%Norm.Core.Schema{specs: specs}, required, root_name, acc) do
    specs
    # `__openapi_name` is a "magic"/internal keyword used to name Schemas. Filter them out.
    |> Enum.reject(fn {name, _} -> name == :__openapi_name end)
    |> Enum.reduce({%{}, acc}, fn {name, spec}, {iacc, acc} ->
      type = get_openapi_type_from_spec(spec, root_name, acc)

      child_schemas =
        case type do
          {:ref, _} ->
            inner_spec_name = spec.schema.specs.__openapi_name
            build_schema(spec, inner_spec_name, acc)

          {:array, {:ref, _}} ->
            inner_spec_name = spec.spec.schema.specs.__openapi_name
            build_schema(spec.spec, inner_spec_name, acc)

          _ ->
            acc
        end

      if is_nil(type) do
        {iacc, child_schemas}
      else
        entry = %{type: type, required: name in required}
        {Map.put(iacc, name, entry), child_schemas}
      end
    end)
  end

  defp get_openapi_type_from_spec(%Norm.Core.Selection{schema: schema}, _root_name, _acc) do
    {:ref, schema.specs.__openapi_name}
  end

  defp get_openapi_type_from_spec(%Norm.Core.Collection{spec: spec}, root_name, acc) do
    {:array, get_openapi_type_from_spec(spec, root_name, acc)}
  end

  defp get_openapi_type_from_spec(%Norm.Core.Spec.And{left: left, right: _right}, name, acc) do
    # NOTE: This is assuming the left-most spec is always the defining one
    get_openapi_type_from_spec(left, name, acc)
  end

  defp get_openapi_type_from_spec(%Norm.Core.Spec{predicate: predicate}, _name, _acc),
    do: type_from_predicate(predicate)

  defp type_from_predicate("is_binary()"), do: :string
  defp type_from_predicate("is_boolean()"), do: :boolean

  ##############################################################################
  # Normalization
  ##############################################################################

  @doc """
  Public for testing.
  """
  def normalize_helix_spec(helix_spec) do
    endpoints =
      helix_spec.endpoints
      |> Enum.map(fn {{endpoint, method}, entry} ->
        id = get_endpoint_id(entry, endpoint)

        normalized_entry =
          entry
          |> normalize_id(id)
          |> normalize_request_body(id)
          |> normalize_responses(id)

        {{endpoint, method}, normalized_entry}
      end)
      |> Map.new()

    %{helix_spec | endpoints: endpoints}
  end

  defp normalize_id(entry, id),
    do: Map.put(entry, :id, id)

  defp normalize_request_body(entry, id),
    do: Map.put(entry, :request_body, get_request_body(entry, id))

  defp normalize_responses(entry, id) do
    normalized_responses =
      entry.responses
      |> Enum.map(fn
        {code, custom_response_component} ->
          {code, custom_response_component}

        code when is_integer(code) ->
          {code, get_response_for_code(code, id)}
      end)
      |> Map.new()

    %{entry | responses: normalized_responses}
  end

  defp get_endpoint_id(%{id: custom_id}, _) when is_binary(custom_id),
    do: custom_id

  defp get_endpoint_id(_, endpoint) do
    [_, _ | rest] = Module.split(endpoint)
    Enum.join(rest)
  end

  defp get_request_body(%{request_body: name}, _), do: name
  defp get_request_body(_, id), do: "#{id}Request"

  defp get_response_for_code(200, id), do: "#{id}OkResponse"
  defp get_response_for_code(400, _), do: "GenericBadRequestResponse"
  defp get_response_for_code(401, _), do: "GenericUnauthorizedResponse"
  defp get_response_for_code(422, _), do: "GenericErrorResponse"
end