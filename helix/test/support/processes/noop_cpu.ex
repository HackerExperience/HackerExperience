defmodule Test.Process.NoopCPU do
  @moduledoc """
  Test dummy process that does nothing upon completion. Uses CPU dynamically.
  """

  use Game.Process.Definition

  defstruct []

  def new(_, _) do
    true = Mix.env() == :test
    %__MODULE__{}
  end

  def get_process_type(_, _), do: :noop_cpu

  def on_db_load(%__MODULE__{} = data), do: data

  defmodule Processable do
    use Game.Process.Processable.Definition
    def on_complete(_process), do: :ok
  end

  defmodule Signalable do
    use Game.Process.Signalable.Definition
  end

  defmodule Resourceable do
    use Game.Process.Resourceable.Definition

    def cpu(_factors, _params, _meta) do
      5000
    end

    def dynamic(_, _, _), do: [:cpu]
    def static(_, _, _), do: %{paused: %{ram: 10}, running: %{ram: 20}}
  end

  defmodule Executable do
  end

  defmodule Viewable do
    use Game.Process.Viewable.Definition

    def spec do
      selection(schema(%{}), [])
    end

    def render_data(_, _, _), do: %{}
  end
end
