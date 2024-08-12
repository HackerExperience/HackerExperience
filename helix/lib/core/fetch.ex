defmodule Core.Fetch do
  @moduledoc """
  `Core.Fetch` provides a standard API meant to support static SQL queries. Static SQL queries are
  the ones defined in .sql files under `priv/queries/**/*.sql`.

  The counterpart to this module is `Core.Search`, which supports dynamic query generation.

  Usually, `Core.fetch` will return a single result and `Core.search` will return multiple results,
  but that's not necessarily a rule and I see no problem in `Core.fetch` returning multiple rows, as
  long as the final API is crystal clear that's a possibility.

  This module is inspired by the TokenOperator library.
  """

  alias DBLite, as: DB

  @doc """
  Runs the filter(s) specified by the caller at `filter_params` and defined by the code at
  `filters_spec`. The caller may also specify custom `opts`. Valid custom `opts` are:

  - includes: list of functions that may be executed post-query. Remember that, in an SQLite world,
  we can run N+1 queries without any kind of worries.
  """
  def query(filter_params, opts, filters_spec, opts_spec \\ []) do
    acc = %{}

    includes = Keyword.get(opts_spec, :includes, [])
    include_params = Keyword.get(opts, :includes, [])

    acc
    |> process(filter_params, filters_spec)
    |> process(include_params, includes)
  end

  defp process(acc, params, functions) do
    Enum.reduce(params, acc, fn
      {fun_name, value}, acc ->
        functions
        |> Keyword.fetch!(fun_name)
        |> execute_callback(acc, value)

      fun_name, acc ->
        functions
        |> Keyword.fetch!(fun_name)
        |> execute_callback(acc)
    end)
  end

  defp execute_callback({:one, query_id}, _acc, value),
    do: DB.one(query_id, value)

  defp execute_callback(fun, acc, value) when is_function(fun) do
    case :erlang.fun_info(fun)[:arity] do
      1 -> fun.(value)
      2 -> fun.(acc, value)
      arity -> raise "Invalid function arity (#{arity}) on #{__MODULE__} callback"
    end
  end

  defp execute_callback(fun, acc) when is_function(fun) do
    case :erlang.fun_info(fun)[:arity] do
      1 -> fun.(acc)
      arity -> raise "Invalid function arity (#{arity}) on #{__MODULE__} callback"
    end
  end
end
