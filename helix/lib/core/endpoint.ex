defmodule Core.Endpoint do
  alias Core.{ID, NIP}

  @doc """
  Casts an external input into a Core.ID format. Note it does NOT check whether the ID exists or
  if the player has authorization to access it.

  Returns an error if:

  - `raw_value` is `nil` when it is not nullable.
  - `raw_value` is of a type different than the one expected by `id_mod`.
  """
  def cast_id(field, raw_value, mod, opts \\ []) do
    id_mod = Module.concat(mod, ID)
    entity_id = Process.get(:helix_session_entity_id)

    cond do
      is_binary(raw_value) ->
        case ID.from_external(raw_value, entity_id) do
          %struct{id: _} = internal_id ->
            # TODO: Validate struct with mod
            {:ok, internal_id}

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
