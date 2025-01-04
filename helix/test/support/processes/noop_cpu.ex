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
    def on_complete(_process), do: :ok
  end

  defmodule Signalable do
    def on_sigterm(_data, _process) do
      # TODO: This is the default (meaning this callback can be removed)
      :delete
    end

    def on_sigstop(_, _) do
      # TODO: This is the default (meaning this callback can be removed)
      :pause
    end

    def on_sigcont(_, _) do
      # TODO: This is the default (meaning this callback can be removed)
      :resume
    end

    def on_sig_renice(_, _) do
      # TODO: This is the default (meaning this callback can be removed)
      :renice
    end
  end

  defmodule Resourceable do
    use Game.Process.Resourceable.Definition

    def cpu(_factors, _params) do
      5000
    end

    def dynamic(_, _), do: [:cpu]
    def static(_, _), do: %{paused: %{ram: 10}, running: %{ram: 20}}
  end

  defmodule Executable do
  end
end
