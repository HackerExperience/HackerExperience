defmodule DB.SchemaFinder do
  @ets_table :detected_schemas
  @target "lib/db/schema/list.ex"

  def run do
    if Mix.env() != :test,
      do: raise("Please run this task again with MIX_ENV=test")

    :ets.new(@ets_table, [:named_table, :public])
    Mix.Task.clear()
    Mix.Task.run("compile", ["--force", "--tracer", __MODULE__])

    # This compilation may be causing the "Inspect protocol is already consolidated" warning
  end

  def trace({:remote_macro, _meta, DB.Schema, :__using__, 1} = _, env) do
    file = env.file
    context = get_context(file)
    :ets.insert(@ets_table, {env.module, context})
    :ok
  end

  def trace(_, _), do: :ok

  def save do
    modules =
      @ets_table
      |> :ets.tab2list()
      |> Enum.map(fn {mod, ctx} ->
        mod =
          mod
          |> to_string()
          |> String.slice(7..-1//1)

        {mod, ctx}
      end)

    total_modules = length(modules)

    modules_list_str =
      modules
      |> Enum.sort_by(fn {mod, ctx} -> {ctx, mod} end)
      |> Enum.with_index()
      |> Enum.reduce("", fn {{mod, ctx}, i}, acc ->
        entry = "{:#{ctx}, #{mod}}"

        cond do
          i == 0 -> "#{entry},"
          i != total_modules - 1 -> "#{acc}\n    #{entry},"
          true -> "#{acc}\n    #{entry}"
        end
      end)

    content = """
    defmodule DB.Schema.List do
      @moduledoc \"\"\"
      This module is generated automatically via `mix db.schema.list`.

      It is used by DB.Boot to load all existing tables and verify their
      SQLite schemas match the schemas defined in the codebase.
      \"\"\"

      @modules [
        #{modules_list_str}
      ]

      @doc \"\"\"
      Returns a list of all the schemas defined in the codebase.
      \"\"\"
      def all, do: @modules
    end
    """

    File.write!(@target, content)
    IO.puts("Written schemas dump to #{@target}")
  end

  defp get_context(path) do
    path
    |> File.read!()
    |> String.split("@context :")
    |> Enum.at(1)
    |> String.split("\n")
    |> List.first()
    |> String.to_atom()
  end
end

DB.SchemaFinder.run()
DB.SchemaFinder.save()
