defmodule Game.Services.PlayerTest do
  use Test.DBCase, async: true
  alias Game.Services, as: Svc

  setup [:with_game_db]

  describe "create/1" do
    test "creates the player" do
      params = Setup.Player.params()
      assert {:ok, player} = Svc.Player.create(params)
      assert player.external_id == params.external_id
    end

    test "auto-increments the player id" do
      assert {:ok, player_1} = Svc.Player.create(Setup.Player.params())
      assert {:ok, player_2} = Svc.Player.create(Setup.Player.params())
      assert {:ok, player_3} = Svc.Player.create(Setup.Player.params())

      assert player_1.id == 1
      assert player_2.id == 2
      assert player_3.id == 3
    end

    @tag capture_log: true
    test "fails if the external_id is already registered" do
      params = Setup.Player.params()
      assert {:ok, _player} = Svc.Player.create(params)
      assert {:error, reason} = Svc.Player.create(params)
      assert reason == "UNIQUE constraint failed: players.external_id"
    end

    test "fails if the external_id is invalid" do
      %{message: reason} =
        assert_raise(RuntimeError, fn ->
          Svc.Player.create(%{external_id: "not_an_uuid"})
        end)

      assert_raise(FunctionClauseError, fn ->
        Svc.Player.create(%{external_id: 50})
      end)

      assert reason =~ "Invalid UUID value"
    end

    test "fails if the external_id is not set" do
      assert {:error, reason} = Svc.Player.create(%{external_id: nil})
      assert reason =~ "Cast error"
      assert reason =~ "external_id: :invalid_input"
    end
  end

  describe "fetch/2 - by_id" do
    test "returns the player when it exists" do
      player = Setup.player()
      assert player == Svc.Player.fetch(by_id: player.id)
    end

    test "returns nil when player doesn't exist" do
      player = Setup.player()
      refute Svc.Player.fetch(by_id: player.id + 1)
    end
  end

  describe "fetch/2 - by_external_id" do
    test "returns the player when it exists" do
      player = Setup.player()
      assert player == Svc.Player.fetch(by_external_id: player.external_id)
    end

    test "returns nil when player doesn't exist" do
      Setup.player()
      refute Svc.Player.fetch(by_external_id: Random.uuid())
    end
  end
end
