defmodule CoreTest do
  use Test.DBCase, async: true

  alias Feeb.DB

  describe "with_context/3" do
    test "can create a context when there is no external context" do
      refute DB.LocalState.has_current_context?()

      # Now we try to start a new context even though there is no external context
      Core.with_context(:universe, :read, fn ->
        assert true
      end)

      Core.with_context(:server, %{id: Random.int()}, :read, fn ->
        assert true
      end)

      Core.with_context(:player, %{id: Random.int()}, :read, fn ->
        assert true
      end)
    end

    test "supports nested contexts (universe, read)" do
      refute DB.LocalState.has_current_context?()

      Core.begin_context(:universe, :read)
      assert DB.LocalState.has_current_context?()

      Core.with_context(:universe, :read, fn ->
        assert true
      end)
    end

    test "supports nested contexts (universe, write)" do
      refute DB.LocalState.has_current_context?()

      Core.begin_context(:universe, :write)
      assert DB.LocalState.has_current_context?()

      Core.with_context(:universe, :write, fn ->
        assert true
      end)

      # We can commit only once, because even though these are nested contexts, they share the same
      # connection under the hood
      DB.commit()
      assert_raise RuntimeError, fn -> DB.commit() end
    end
  end
end
