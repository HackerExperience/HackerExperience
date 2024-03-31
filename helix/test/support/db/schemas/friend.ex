defmodule Sample.Friend do
  use DB.Schema
  alias DB.Schema

  @context :test
  @table :friends

  @schema [
    {:id, :integer},
    {:name, :string}
  ]

  def new(params) do
    params
    |> Schema.cast(:all)
    |> Schema.create()
  end
end
