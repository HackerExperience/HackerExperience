defmodule Game.Software.Manifest do
  @moduledoc """
  Converts the Software definition into a standard format that can be consumed by the Client.
  """

  use Norm
  import Core.Spec
  alias Game.Software

  def spec do
    software_spec =
      selection(
        schema(%{
          __openapi_name: "SoftwareManifest",
          type: enum(Software.types(:all) |> Enum.map(&to_string/1)),
          extension: binary(),
          config: Software.Config.spec()
        }),
        [:type, :extension, :config]
      )

    coll_of(software_spec)
  end

  def render(software) do
    software
    |> Enum.reduce([], fn {_, s}, acc ->
      config =
        s.config
        |> Map.from_struct()
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)
        |> Map.new()

      [%{type: "#{s.type}", extension: "#{s.extension}", config: config} | acc]
    end)
  end
end
