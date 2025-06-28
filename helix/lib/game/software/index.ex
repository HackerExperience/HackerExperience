defmodule Game.Index.Software do
  use Norm
  alias Game.{Software}

  @type index ::
          %{manifest: list()}

  @type rendered_index ::
          %{manifest: map()}

  def output_spec do
    selection(
      schema(%{
        __openapi_name: "IdxSoftware",
        manifest: Software.Manifest.spec()
      }),
      [:manifest]
    )
  end

  @spec index() ::
          index
  def index do
    %{manifest: Software.all()}
  end

  @spec render_index(index) ::
          rendered_index
  def render_index(index) do
    %{manifest: Software.Manifest.render(index.manifest)}
  end
end
