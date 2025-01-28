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
          struct(Core.ID.ref(id_ref), %{id: id})

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
