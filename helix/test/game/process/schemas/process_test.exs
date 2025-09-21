defmodule Game.ProcessTest do
  use Test.DBCase, async: true

  alias Game.Process

  setup [:with_game_db]

  describe "new/1" do
    test "raises if the `data` struct belongs to a different process" do
      entity = Setup.entity_lite!()
      server = Setup.server_lite!()

      %{data: noop_dlk_data} = Setup.process_spec(server.id, entity.id, type: :noop_dlk)
      DB.commit()

      %{message: error} =
        assert_raise RuntimeError, fn ->
          %{
            entity_id: entity.id,
            type: :noop_cpu,
            data: noop_dlk_data,
            registry: %{},
            status: :awaiting_allocation,
            resources: %{},
            priority: 3
          }
          |> Process.new()
        end

      assert error =~ "Bad process data"
    end
  end
end
