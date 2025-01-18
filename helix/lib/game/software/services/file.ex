defmodule Game.Services.File do
  alias Feeb.DB
  alias Game.{File, FileVisibility}

  def fetch(filter_params, opts \\ []) do
    filters = [
      by_id: {:one, {:files, :fetch}}
    ]

    Core.Fetch.query(filter_params, opts, filters)
  end

  def fetch!(filter_params, opts \\ []) do
    filter_params
    |> fetch(opts)
    |> Core.Fetch.assert_non_empty_result!(filter_params, opts)
  end
end
