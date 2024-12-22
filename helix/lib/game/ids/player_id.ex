defmodule Game.Player.ID do
  @moduledoc """
  Because Player/Entity IDs are interchangeable, we don't use the generic macros for them.
  """

  alias Game.Entity

  @behaviour Feeb.DB.Type.Behaviour
  @type t :: %__MODULE__{id: integer}

  defstruct [:id]

  def new(id) when is_integer(id), do: %__MODULE__{id: id}
  def new(%__MODULE__{} = id), do: id
  def new(%Entity.ID{id: raw_id}), do: %__MODULE__{id: raw_id}

  @impl true
  def sqlite_type, do: :integer

  @impl true
  def cast!(v, _, _) when is_integer(v), do: %__MODULE__{id: v}
  def cast!(%__MODULE__{} = id, _, _), do: id
  def cast!(%Game.Entity.ID{id: entity_id}, _, _), do: %__MODULE__{id: entity_id}

  @impl true
  def dump!(v, _, _) when is_integer(v), do: v
  def dump!(%__MODULE__{id: v}, _, _), do: v

  @impl true
  def load!(v, _, _) when is_integer(v), do: %__MODULE__{id: v}

  defimpl String.Chars do
    def to_string(%{id: id}), do: "#{id}"
  end

  def from_endpoint(nil, opts),
    do: if(opts[:optional], do: {:ok, nil}, else: {:error, :empty})

  def from_endpoint(raw_id, _opts) when is_integer(raw_id),
    do: {:ok, from_external(raw_id)}

  def from_endpoint(_, _),
    do: {:error, :invalid}

  def from_external(id) when is_integer(id),
    do: %__MODULE__{id: id}
end
