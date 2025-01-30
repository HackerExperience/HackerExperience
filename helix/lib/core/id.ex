defmodule Core.ID do
  @type external :: binary()
  @type internal :: integer()

  defmacro __using__(_) do
    quote do
      @behaviour Feeb.DB.Type.Behaviour

      @type t :: %__MODULE__{id: integer()}

      defstruct [:id]

      def new(id) when is_integer(id),
        do: %__MODULE__{id: id}

      @impl true
      def sqlite_type, do: :integer

      @impl true
      def cast!(v, _, _) when is_integer(v), do: %__MODULE__{id: v}
      def cast!(%__MODULE__{} = id, _, _), do: id
      def cast!(nil, %{nullable: true}, _), do: nil

      @impl true
      def dump!(v, _, _) when is_integer(v), do: v
      def dump!(%__MODULE__{id: v}, _, _), do: v
      def dump!(nil, %{nullable: true}, _), do: nil

      @impl true
      def load!(v, _, _) when is_integer(v), do: %__MODULE__{id: v}
      def load!(nil, %{nullable: true}, _), do: nil

      defimpl String.Chars do
        def to_string(%{id: id}), do: "#{id}"
      end
    end
  end

  def to_external(%struct{id: id}, %_{} = player_id, domain_id \\ nil, subdomain_id \\ nil) do
    object_type =
      struct
      |> to_string()
      |> String.split(".")
      |> Enum.at(-2)
      |> __MODULE__.External.get_object_type()

    domain_id =
      case domain_id do
        %_{id: id} -> id
        nil -> nil
      end

    subdomain_id =
      case subdomain_id do
        %_{id: id} -> id
        nil -> nil
      end

    __MODULE__.External.to_external(player_id, {id, object_type, domain_id, subdomain_id})
  end

  def from_external(external_id, player_id) do
    __MODULE__.External.from_external(external_id, player_id)
  end

  @doc """
  We reference the corresponding ID modules in such a way to not create compile-time dependencies.
  """
  def ref(:connection_id), do: :"Elixir.Game.Connection.ID"
  def ref(:connection_group_id), do: :"Elixir.Game.ConnectionGroup.ID"
  def ref(:entity_id), do: :"Elixir.Game.Entity.ID"
  def ref(:file_id), do: :"Elixir.Game.File.ID"
  def ref(:installation_id), do: :"Elixir.Game.Installation.ID"
  def ref(:log_id), do: :"Elixir.Game.Log.ID"
  def ref(:player_id), do: :"Elixir.Game.Player.ID"
  def ref(:process_id), do: :"Elixir.Game.Process.ID"
  def ref(:server_id), do: :"Elixir.Game.Server.ID"
  def ref(:tunnel_id), do: :"Elixir.Game.Tunnel.ID"
end
