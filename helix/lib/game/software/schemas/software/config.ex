defmodule Game.Software.Config do
  use Norm
  import Core.Spec

  defstruct [:appstore]

  def spec do
    appstore_spec =
      selection(
        schema(%{
          __openapi_name: "SoftwareConfigAppstore",
          price: integer()
        }),
        [:price]
      )

    selection(
      schema(%{
        __openapi_name: "SoftwareConfig",
        appstore: appstore_spec
      }),
      []
    )
  end

  def new, do: %__MODULE__{appstore: nil}

  def with_appstore(config, opts \\ []) do
    appstore_config = %{price: opts[:price] || 0}
    %{config | appstore: appstore_config}
  end
end
