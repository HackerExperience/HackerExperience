defmodule Game.Software do
  defstruct [:type, :extension, :config]

  alias Game.Software.Config, as: SoftwareConfig

  def all do
    base_config = SoftwareConfig.new()

    %{
      cracker: %__MODULE__{
        type: :cracker,
        extension: :crc,
        config:
          base_config
          |> SoftwareConfig.with_appstore()
      },
      log_editor: %__MODULE__{
        type: :log_editor,
        extension: :log,
        config: base_config
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
end
