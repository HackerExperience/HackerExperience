defmodule Game.Webserver.Spec do
  @doc """
  DOCME
  """
  def spec do
    %{
      title: "Game API",
      version: "1.0.0",
      endpoints: endpoints(),
      default_responses: default_responses(),
      default_schemas: default_schemas()
    }
  end

  defp endpoints do
    %{
      # TODO: It's Sync, not Login
      {Lobby.Endpoint.User.Login, :post} => %{
        path: "/v1/user/login",
        responses: [200, 400, 401, 422]
      }
    }
  end

  # TODO: Error defaults are shared between Lobby and Game.{MP|SP}. DRY it
  defp default_schemas do
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

  # TODO: Error defaults are shared between Lobby and Game.{MP|SP}. DRY it
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
