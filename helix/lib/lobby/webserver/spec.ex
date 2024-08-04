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
        responses: [200, 401, 422]
      },
      {Lobby.Endpoint.User.Register, :post} => %{
        path: "/v1/user/register",
        responses: [200, 422]
      }
    }
  end

  defp default_schemas do
    %{
      "GenericError" => %{
        type: :object,
        required: [:error],
        properties: %{
          error: %{type: :string}
        }
      }
    }
  end

  defp default_responses do
    %{
      "GenericErrorResponse" => %{
        description: "TODO",
        content: %{
          "application/json" => %{
            schema: %{
              "$ref" => "\#/components/schemas/GenericError"
            }
          }
        }
      },
      "GenericUnauthorizedResponse" => %{
        description: "TODO",
        content: %{}
      }
    }
  end
end
