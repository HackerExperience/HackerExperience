defmodule Test.Process.NoopDLK do
  @moduledoc """
  Test dummy process that does nothing upon completion. Uses DLK dynamically.
  """

  use Game.Process.Definition

  defstruct []

  def new(_, _) do
    true = Mix.env() == :test
    %__MODULE__{}
  end

  def get_process_type(_, _), do: :noop_dlk

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

    def dlk(_factors, _params, _meta) do
      5000
    end

    def dynamic(_, _, _), do: [:dlk]
    def static(_, _, _), do: %{paused: %{ram: 10}, running: %{ram: 20}}

    def limit(_, params, _) do
      %{ulk: params[:ulk_limit] || 500}
    end
  end

  defmodule Executable do
  end
end
