defmodule Core.ID.External do
  alias Feeb.DB
  alias Game.ExternalID

  def to_external(player_id, internal_identifier) do
    # TODO: Maybe should only select `external_id` instead of `select *`?
    case query_by_internal_id(player_id, internal_identifier) do
      %_{external_id: external_id} ->
        external_id

      nil ->
        {:ok, entry} = generate_external_id(player_id, internal_identifier)
        entry.external_id
    end
  end

  def from_external(external_id, player_id) when is_binary(external_id) do
    Core.with_context(:player, player_id, :read, fn ->
      case DB.one({:external_ids, :fetch}, [external_id]) do
        %ExternalID{object_id: id, object_type: id_ref} ->
          struct(Core.ID.Definition.ref(id_ref), %{id: id})

        nil ->
          nil
      end
    end)
  end

  def get_object_type("X"), do: :x

  def get_object_type(schema_name) do
    schema_name
    |> String.downcase()
    |> Kernel.<>("_id")
    |> String.to_existing_atom()
  end

  defp generate_external_id(player_id, {object_id, type, domain_id, subdomain_id}) do
    result =
      Core.with_context(:player, player_id, :write, fn ->
        %{
          external_id: Renatils.Random.uuid(),
          object_id: object_id,
          object_type: type,
          domain_id: domain_id,
          subdomain_id: subdomain_id
        }
        |> ExternalID.new()
        |> DB.insert()
      end)

    # If the outter context is a :read connection on Player, restart it so the new connection
    # can "see" this newly generated entry. This should not happen often; usually Player is the
    # outter context only when Index is being rendered, and even then for most cases the Player
    # should already have an entry matching the internal ID (meaning an external one doesn't have to
    # be generated). Somewhat of a dirty hack, but since it happens infrequently I'm okay with it.
    case Core.get_current_context() do
      {ctx, _, :read} when ctx in [:sp_player, :mp_player] ->
        Core.commit()
        Core.begin_context(:player, player_id, :read)

      _ ->
        :noop
    end

    result
  end

  defp query_by_internal_id(player_id, {object_id, type, nil, nil}),
    do: do_query(player_id, :by_internal_id_nodomain, [object_id, type])

  defp query_by_internal_id(player_id, {object_id, type, domain_id, nil}),
    do: do_query(player_id, :by_internal_id_nosubdomain, [object_id, type, domain_id])

  defp query_by_internal_id(player_id, {object_id, type, domain_id, subdomain_id}),
    do: do_query(player_id, :by_internal_id_full, [object_id, type, domain_id, subdomain_id])

  defp do_query(player_id, query_name, query_params) do
    Core.with_context(:player, player_id, :read, fn ->
      DB.one({:external_ids, query_name}, query_params)
    end)
  end
end
