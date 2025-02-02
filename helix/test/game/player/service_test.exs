defmodule Game.Services.PlayerTest do
  use Test.DBCase, async: true
  alias Game.Services, as: Svc

  setup [:with_game_db]

  describe "setup/1" do
    setup [:with_random_autoincrement]

    test "creates the player and the entity" do
      external_id = Random.uuid()
      assert {:ok, player} = Svc.Player.setup(external_id)
      assert player.external_id == external_id

      # We can find the player in the database
      assert player == DB.one({:players, :fetch}, player.id)

      # We can find the entity with the same id
      entity = DB.one({:entities, :fetch}, player.id)
      assert entity.type == :player
      assert entity.inserted_at
    end

    test "creates an initial server for the player" do
      assert {:ok, player} = Svc.Player.setup(Random.uuid())

      # We can find a Server entry for this entity
      assert [server] = Svc.Server.list(by_entity_id: player.id)
      assert server.entity_id.id == player.id.id
    end

    test "auto-increments the player id" do
      assert {:ok, player_1} = Svc.Player.setup(Random.uuid())
      assert {:ok, player_2} = Svc.Player.setup(Random.uuid())
      assert {:ok, player_3} = Svc.Player.setup(Random.uuid())

      assert player_2.id.id == player_1.id.id + 1
      assert player_3.id.id == player_1.id.id + 2
    end

    @tag capture_log: true
    test "fails if the external_id is already registered" do
      external_id = Random.uuid()
      assert {:ok, _player} = Svc.Player.setup(external_id)
      assert {:error, reason} = Svc.Player.setup(external_id)
      assert reason == "UNIQUE constraint failed: players.external_id"
    end

    test "fails if the external_id is invalid" do
      %{message: reason} =
        assert_raise(RuntimeError, fn ->
          Svc.Player.setup("not_an_uuid")
        end)

      assert_raise(FunctionClauseError, fn ->
        Svc.Player.setup(50)
      end)

      assert_raise(FunctionClauseError, fn ->
        Svc.Player.setup(nil)
      end)

      assert reason =~ "Invalid UUID value"
    end
  end

  describe "fetch/2 - by_id" do
    test "returns the player when it exists" do
      player = Setup.player!()
      assert player == Svc.Player.fetch(by_id: player.id)
    end

    test "returns nil when player doesn't exist" do
      player = Setup.player!()
      refute Svc.Player.fetch(by_id: player.id.id + 1)
    end
  end

  describe "fetch/2 - by_external_id" do
    test "returns the player when it exists" do
      player = Setup.player!()
      assert player == Svc.Player.fetch(by_external_id: player.external_id)
    end

    test "returns nil when player doesn't exist" do
      Setup.player!()
      refute Svc.Player.fetch(by_external_id: Random.uuid())
    end
  end

  describe "fetch!/2" do
    test "raises if no results were found" do
      uuid = Random.uuid()

      %{message: error} =
        assert_raise RuntimeError, fn ->
          Svc.Player.fetch!(by_external_id: uuid)
        end

      assert error =~ "Expected some result"
      assert error =~ "by_external_id: \"#{uuid}"
      assert error =~ "got `nil`"
    end
  end
end
