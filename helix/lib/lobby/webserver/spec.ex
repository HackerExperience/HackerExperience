defmodule Lobby.Webserver.Spec do
  @doc """
  DOCME
  """
  def spec do
    %{
      title: "Lobby API",
      version: "1.0.0",
      endpoints: endpoints(),
      default_responses: default_responses(),
      default_schemas: default_schemas()
    }
  end

  defp endpoints do
    %{
      {Lobby.Endpoint.User.Login, :post} => %{
        path: "/v1/user/login",
        responses: [200, 400, 401, 422]
      },
      {Lobby.Endpoint.User.Register, :post} => %{
        path: "/v1/user/register",
        responses: [200, 400, 422]
      }
    }
  end

  defp default_schemas do
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

  defp default_responses do
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
