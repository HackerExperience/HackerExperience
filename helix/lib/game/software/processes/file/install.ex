defmodule Game.Process.File.Install do
  use Game.Process.Definition

  alias Game.{File}

  defstruct [:file_id]

  def new(_, %{file: %File{} = file}) do
    %__MODULE__{file_id: file.id}
  end

  def get_process_type(_, _), do: :file_install

  defmodule Processable do
    use Game.Process.Processable.Definition

    def on_complete(_process) do
      # TODO: Create an Installation for the File
      :ok
    end
  end

  defmodule Signalable do
    use Game.Process.Signalable.Definition

    # TODO: Kill process when source file is deleted
  end

  defmodule Resourceable do
    use Game.Process.Resourceable.Definition

    def cpu(_factors, _param, _meta) do
      # TODO
      5000
    end

    # TODO: Maybe IOPS? Or IOPS + CPU?
    def dynamic(_, _, _), do: [:cpu]

    def static(_, _, _) do
      %{
        paused: %{ram: 10},
        running: %{ram: 20}
      }
    end
  end

  defmodule Executable do
    alias Game.File

    def source_file(_server_id, _entity_id, _params, %{file: %File{} = file}, _),
      do: file
  end
end
