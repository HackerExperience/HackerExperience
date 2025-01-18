defmodule Game.Henforcers.File do
  alias Core.Henforcer
  alias Game.Services, as: Svc
  alias Game.{File, Server}

  @type file_exists_relay :: %{file: File.t()}
  @type file_exists_error :: {false, {:file, :not_Found}, %{}}

  @doc """
  Checks whether the given File exists.
  """
  @spec file_exists?(File.ID.t(), Server.t()) ::
          {true, file_exists_relay}
          | file_exists_error
  def file_exists?(%File.ID{} = file_id, %Server{} = server) do
    Core.with_context(:server, server.id, :read, fn ->
      case Svc.File.fetch(by_id: file_id) do
        %File{} = file ->
          Henforcer.success(%{file: file})

        nil ->
          Henforcer.fail({:file, :not_found})
      end
    end)
  end
end
