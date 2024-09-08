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

  alias Feeb.DB

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

  @doc """
  Function used to implement the equivalent of `fetch!/2`. Will raise an error if no rows were
  returned, when at least one was expected to be found.
  """
  def assert_non_empty_result!(result, filter_params, opts) when result in [nil, []] do
    # NOTE: At least for now, I'm keeping `[]` here as possible result of empty list; but I see
    # myself moving away from this pattern in the future and making Core.Fetch exclusive for single
    # row retrieval. Maybe we could create a similar Core.List API meant for collections?
    raise "Expected some result for #{inspect(filter_params)} (opts #{inspect(opts)}); got `nil`"
  end

  def assert_non_empty_result!(valid_result, _, _), do: valid_result

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

  defp execute_callback({:all, query_id}, _acc, value),
    do: DB.all(query_id, value)

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
