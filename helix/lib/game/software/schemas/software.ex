defmodule Game.Software do
  defstruct [:type, :extension, :config]

  def all do
    %{
      cracker: %__MODULE__{
        type: :cracker,
        extension: :crc,
        config: %{
          appstore: %{
            price: 0
          }
        }
      },
      log_editor: %__MODULE__{
        type: :log_editor,
        extension: :log,
        config: %{}
      }
    }
  end

  def get(type) do
    Map.fetch!(all(), type)
  end

  def types(:all), do: Map.keys(all())

  def types(:installable) do
    # TODO (generate based on @software)
    [:cracker]
  end

  defmodule Manifest do
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
            extension: binary()
          }),
          [:type, :extension]
        )

      coll_of(software_spec)
    end

    def render(software) do
      software
      |> Renatils.Map.destructify()
      |> Enum.reduce([], fn {_, s}, acc ->
        [%{s | type: "#{s.type}", extension: "#{s.extension}"} | acc]
      end)
    end
  end
end
