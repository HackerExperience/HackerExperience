defmodule Core.FetchTest do
  use Test.DBCase, async: true

  alias Core.Fetch

  setup [:with_game_db]

  describe "query/4" do
    test "filtering in a custom function with arity 1" do
      server = Setup.server_lite!()

      query_by_log_visibility = fn value ->
        assert value == %{server_id: server.id, entity_id: server.entity_id}
      end

      filters = [
        by_visibility: query_by_log_visibility
      ]

      input = [by_visibility: %{server_id: server.id, entity_id: server.entity_id}]

      Fetch.query(input, [], filters)
    end
  end
end
