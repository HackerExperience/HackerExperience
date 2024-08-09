defmodule Core.Webserver.Spec do
  @doc """
  These are shared across GameAPI and LobbyAPI.
  """
  def default_schemas do
    # TODO: Ideally, these schemas should be generated off of Endpoint.output_spec_for_error
    %{
      "GenericBadRequest" => %{
        type: :object,
        required: [:msg],
        properties: %{
          msg: %{type: :string},
          details: %{type: :string}
        }
      },
      "GenericError" => %{
        type: :object,
        required: [:msg],
        properties: %{
          msg: %{type: :string},
          details: %{type: :string}
        }
      }
    }
  end

  @doc """
  These are shared across GameAPI and LobbyAPI.
  """
  def default_responses do
    %{
      # 400
      "GenericBadRequestResponse" => %{
        description: "TODO",
        content: %{
          "application/json" => %{
            schema: %{
              type: :object,
              required: [:error],
              properties: %{
                error: %{
                  "$ref" => "#/components/schemas/GenericBadRequest"
                }
              }
            }
          }
        }
      },
      # 401
      "GenericUnauthorizedResponse" => %{
        description: "TODO",
        content: %{}
      },
      # 422
      "GenericErrorResponse" => %{
        description: "TODO",
        content: %{
          "application/json" => %{
            schema: %{
              type: :object,
              required: [:error],
              properties: %{
                error: %{
                  "$ref" => "#/components/schemas/GenericError"
                }
              }
            }
          }
        }
      }
    }
  end
end
