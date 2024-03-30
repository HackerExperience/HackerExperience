defmodule DB.Boot do
  require Logger

  @queries_path "priv/queries/**/*.sql"
  @env Mix.env()

  # TODO: This should be in a config
  if Mix.env() == :test do
    @contexts [:test, :lobby]
  else
    @contexts [:lobby]
  end

  def run do
    {t, _} = :timer.tc(fn -> migrate_shards() end)
    Logger.info("Shards migrated in #{trunc(t / 1000)}ms")

    {t, _} = :timer.tc(fn -> setup() end)
    Logger.info("DB setup completed in #{trunc(t / 1000)}ms")
  end

  ##############################################################################
  # Functions below this point are internal. They may be public for testing
  # purposes only, but they should not be called directly. Only Boot.run/0 is a
  # valid entrypoint for this module.
  ##############################################################################

  def setup do
    all_models = get_all_models()
    all_queries = get_all_queries()
    compile_queries(all_queries)

    Enum.each(@contexts, fn context ->
      shard_id =
        if @env == :test and context == :test do
          mod = :"Elixir.Test.DB.Setup"
          {:ok, shard_id, _path} = mod.new_test_db(:simple)
          shard_id
        else
          1
        end

      save_database_metadata(all_models, context)
      DB.begin(context, shard_id, :read)
      validate_database(all_models, context)
      DB.commit()
    end)
  end

  # TODO: Test this function somehow (maybe create a fake datadir
  # with mock DBs to be migrated). Also test that they can receive
  # requests as the other shards are being migrated
  def migrate_shards do
    DB.Migrator.setup()

    Enum.each(@contexts, fn context ->
      :done = migrate_shards_for_context(context)
    end)
  end

  def get_all_models do
    DB.Schema.List.all()
    |> filter_models_by_env()
    |> Enum.map(fn {context, mod} ->
      true = is_atom(mod.__table__())
      {mod, context, mod.__table__(), mod.__schema__()}
    end)
  end

  def get_all_queries do
    # TODO: Make it configurable so it works with test/prod queries
    @queries_path
    |> Path.wildcard()
    |> Enum.map(fn path ->
      name =
        path
        |> String.slice(13..-1//1)
        |> String.split(".")
        |> List.first()

      [context, domain] =
        name
        |> String.split("/")
        |> Enum.map(&String.to_atom/1)

      {context, domain, path}
    end)
  end

  def compile_queries(all_queries) do
    # Compile each context query
    all_queries
    |> Enum.each(fn {context, domain, path} ->
      DB.Query.compile(path, {context, domain})
    end)

    # TODO: Also compile "empty" (non-existent) query files, since we may only use
    # the templated queries and that should still be fine
  end

  def save_database_metadata(all_models, context) do
    all_models
    |> Enum.filter(fn {_, ctx, _, _} -> ctx == context end)
    |> Enum.map(fn model ->
      save_model(model)
      save_table_fields(model)
    end)
  end

  def validate_database(all_models, context) do
    all_models
    |> Enum.map(fn {_module, _context, table, _schema} = model ->
      {:ok, table_info} = DB.raw("PRAGMA table_info(#{table})")
      validate_table_info!(model, table_info)
    end)
  end

  defp validate_table_info!({model, context, _table, schema}, table_info) do
    table_fields =
      Enum.map(table_info, fn [_, field, _, _, _, _] ->
        String.to_atom(field)
      end)

    if length(table_fields) != length(Map.keys(schema)) do
      schema_fields = Map.keys(schema)

      extra_fields =
        if length(table_fields) > length(schema_fields),
          do: table_fields -- schema_fields,
          else: schema_fields -- table_fields

      "Schema fields and #{context}@#{model} fields do not match: #{inspect(extra_fields)}"
      |> raise()
    end

    Enum.each(table_info, fn [_, field, sqlite_type, _nullable?, _default, _pk?] ->
      # TODO: Validate nullable
      # TODO: Validate PK
      field = String.to_atom(field)

      if not Map.has_key?(schema, field),
        do: raise("Unable to find field #{field} on #{model}")

      {type_module, _, _} = Map.fetch!(schema, field)
      field_type = type_module.sqlite_type()

      case {sqlite_type, field_type} do
        {"INTEGER", :integer} ->
          :ok

        {"TEXT", :text} ->
          :ok

        {"REAL", :real} ->
          :ok

        {"BLOB", :blob} ->
          :ok

        _ ->
          raise "Type mismatch: #{sqlite_type}/#{field_type} for #{field} @ #{model}"
      end
    end)
  end

  defp save_table_fields({model, _context, _table, _schema}) do
    fields = model.__cols__()
    :persistent_term.put({:db_table_fields, model}, fields)
  end

  defp save_model({model, context, table, _}) do
    :persistent_term.put({:db_table_models, {context, table}}, model)
  end

  defp migrate_shards_for_context(context, n \\ 1) do
    case do_migrate_shard(context, n) do
      :ok -> migrate_shards_for_context(context, n + 1)
      {:error, :shard_not_found} -> :done
    end
  end

  defp do_migrate_shard(context, shard_id) do
    path = DB.Repo.get_path(context, shard_id)

    continue_migrating? =
      cond do
        # The `lobby` context has a single global shard with a hard-coded path
        context == :lobby and shard_id > 1 ->
          false

        {:error, :enoent} == File.stat(path) ->
          false

        :else ->
          true
      end

    if continue_migrating? do
      DB.begin(context, shard_id, :write)
      DB.commit()
      # TODO: close
      :ok
    else
      {:error, :shard_not_found}
    end
  end

  defp filter_models_by_env(models) do
    if @env != :test do
      Enum.reject(models, fn {domain, _} -> domain == :test end)
    else
      models
    end
  end
end
