defmodule Core.Metrics.DB do
  def setup do
    Hotel.Metrics.define_sum("db.queries.total")
  end
end
