defmodule Core.ID do
  defmacro __using__(_) do
    quote do
      @behaviour Feeb.DB.Type.Behaviour

      defstruct [:id]

      @impl true
      def sqlite_type, do: :integer

      @impl true
      def cast!(v, _, _) when is_integer(v), do: %__MODULE__{id: v}
      def cast!(%__MODULE__{} = id, _, _), do: id

      @impl true
      def dump!(v, _, _) when is_integer(v), do: v
      def dump!(%__MODULE__{id: v}, _, _), do: v

      @impl true
      def load!(v, _, _) when is_integer(v), do: %__MODULE__{id: v}

      defimpl String.Chars do
        def to_string(%{id: id}), do: "#{id}"
      end
    end
  end

  def to_external(%_{id: id}), do: id

  @doc """
  We reference the corresponding ID modules in such a way to not create compile-time dependencies.
  """
  def ref(:entity_id), do: :"Elixir.Game.Entity.ID"
  def ref(:log_id), do: :"Elixir.Game.Log.ID"
  def ref(:player_id), do: :"Elixir.Game.Player.ID"
  def ref(:server_id), do: :"Elixir.Game.Server.ID"
  def ref(:tunnel_id), do: :"Elixir.Game.Tunnel.ID"
end
