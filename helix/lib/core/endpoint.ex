defmodule Core.Endpoint do
  alias Core.NIP

  @doc """
  Casts an external input into a Core.ID format. Note it does NOT check whether the ID exists or
  if the player has authorization to access it.

  Returns an error if:

  - `raw_value` is `nil` when it is not nullable.
  - `raw_value` is of a type different than the one expected by `id_mod`.
  """
  def cast_id(field, raw_value, mod, opts) do
    id_mod = Module.concat(mod, ID)

    case id_mod.from_endpoint(raw_value, opts) do
      {:ok, id} ->
        {:ok, id}

      {:error, reason} ->
        {:error, {field, reason}}
    end
  end

  @doc """
  Casts an external input into a Core.NIP format. Note it does NOT check whether the NIP exists or
  if the player has authorization to access it.
  """
  def cast_nip(field, raw_value) do
    case NIP.parse_external(raw_value) do
      {:ok, nip} ->
        {:ok, nip}

      {:error, reason} ->
        {:error, {field, reason}}
    end
  end
end
