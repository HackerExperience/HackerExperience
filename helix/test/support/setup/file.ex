defmodule Test.Setup.File do
  use Test.Setup.Definition
  alias Game.{File, FileVisibility}

  def new(server_id, opts \\ []) do
    Core.with_context(:server, server_id, :write, fn ->
      file =
        opts
        |> params()
        |> File.new()
        |> DB.insert!()

      file_visibility =
        if Keyword.has_key?(opts, :visible_by) do
          entity_id = Keyword.fetch!(opts, :visible_by)

          new_visibility!(entity_id,
            server_id: server_id,
            file_id: file.id
          )
        end

      installation =
        if opts[:installed] || opts[:installed?] do
          {:ok, installation} = Svc.File.install_file(file)
          installation
        end

      %{file: file, file_visibility: file_visibility, installation: installation}
    end)
  end

  def new!(server_id, opts \\ []),
    do: server_id |> new(opts) |> Map.fetch!(:file)

  def new_visibility(player_id, opts \\ []) do
    Core.with_context(:player, player_id, :write, fn ->
      file_visibility =
        opts
        |> visibility_params()
        |> FileVisibility.new()
        |> DB.insert!()

      %{file_visibility: file_visibility}
    end)
  end

  def new_visibility!(player_id, opts \\ []),
    do: player_id |> new_visibility(opts) |> Map.fetch!(:file_visibility)

  def params(opts \\ []) do
    %{
      type: Kw.get(opts, :type, :log_editor),
      name: Kw.get(opts, :name, Random.uuid()),
      version: Kw.get(opts, :version, 10),
      size: Kw.get(opts, :size, 1),
      path: Kw.get(opts, :path, "/")
    }
  end

  def visibility_params(opts \\ []) do
    %{
      server_id: Kw.get(opts, :server_id, Random.int()),
      file_id: Kw.get(opts, :file_id, Random.int())
    }
  end
end
