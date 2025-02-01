defmodule Core.Endpoint do
  alias Core.{ID, NIP}

  @doc """
  Casts an external ID (string) into the internal Core.ID format (integer). It relies on the
  ID.External implementation and ensures that the given ID:
  1. Exists in the database at one point (it might have been deleted in the corresponding source of
     truth -- remember that the external ID is more like a cache of IDs the entity has access to).
  2. Belongs to the same type expected by the caller, as defined by the schema `mod`.

  Returns an error if:

  - `raw_value` does not exist and therefore cannot map to an internal ID.
  - `raw_value` is `nil` when it is not nullable.
  - `raw_value` is of a type different than the one expected by `id_mod`.
  - `raw_value` is not a string.
  """
  def cast_id(field, raw_value, mod, opts \\ []) do
    id_mod = Module.concat(mod, Elixir.ID)
    entity_id = Process.get(:helix_session_entity_id) || raise "Missing entity_id in process"

    cond do
      is_binary(raw_value) ->
        case ID.from_external(raw_value, entity_id) do
          %id_struct{id: _} = internal_id ->
            # Make sure the external ID passed as input belongs to an object of the same type that
            # we are expecting. The type we are expecting is defined by `mod`.
            if id_struct == id_mod do
              {:ok, internal_id}
            else
              {:error, {field, :id_not_found}}
            end

          nil ->
            {:error, {field, :id_not_found}}
        end

      is_nil(raw_value) and opts[:optional] ->
        {:ok, nil}

      is_nil(raw_value) ->
        {:error, {field, :empty}}

      true ->
        {:error, {field, :invalid}}
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

  def cast_enum(field, raw_value, allowed_values) do
    if raw_value in allowed_values do
      {:ok, raw_value}
    else
      {:error, {field, :invalid}}
    end
  end

  def format_cast_error({field, :invalid_nip}), do: "#{field}:invalid_nip"
  def format_cast_error({field, {:invalid_ip, _}}), do: "#{field}:invalid_nip"
  def format_cast_error({field, {:invalid_network_id, _}}), do: "#{field}:invalid_nip"
  def format_cast_error({field, :id_not_found}), do: "#{field}:id_not_found"
  def format_cast_error({field, :invalid}), do: "#{field}:invalid_input"
  def format_cast_error({field, :empty}), do: "#{field}:missing"
end
