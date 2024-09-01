defmodule Test.Setup.Server do
  use Test.Setup
  alias Game.ServerMapping

  def new(opts \\ []) do
    source_entity = get_source_entity(opts)

    # TODO: Create server DB if requested

    server_mapping =
      [entity_id: source_entity.id]
      |> Keyword.merge(opts)
      |> mapping_params()
      |> ServerMapping.new()
      |> DB.insert!()

    %{
      server_mapping: server_mapping,
      entity: source_entity
    }
  end

  def new!(opts \\ []), do: opts |> new() |> Map.fetch!(:server_mapping)

  def mapping_params(opts \\ []) do
    %{entity_id: Kw.fetch!(opts, :entity_id)}
  end

  defp get_source_entity(opts) do
    cond do
      entity = Kw.get(opts, :entity, false) ->
        true = entity.__struct__ == Game.Entity
        entity

      :else ->
        S.Entity.new!()
    end
  end
end
