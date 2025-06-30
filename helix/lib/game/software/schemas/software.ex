defmodule Game.Software do
  defstruct [:type, :extension, :config]

  alias Game.Software.Config, as: SoftwareConfig

  @type t :: %__MODULE__{
          type: type(),
          extension: atom(),
          config: map
        }

  @type type ::
          :cracker
          | :log_editor

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

  def get(type), do: Map.get(all(), type)
  def get!(type), do: Map.fetch!(all(), type)

  def types(:all), do: Map.keys(all())

  def types(:installable) do
    # TODO (generate based on @software)
    [:cracker]
  end
end
