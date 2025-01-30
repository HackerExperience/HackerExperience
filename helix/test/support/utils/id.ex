defmodule Test.Utils.ID do
  alias Core.ID

  def to_eid(object_id, entity_id, domain_id \\ nil, subdomain_id \\ nil),
    do: ID.to_external(object_id, entity_id, domain_id, subdomain_id)

  def from_external_id(external_id, entity_id) when is_binary(external_id),
    do: ID.External.from_external(external_id, entity_id)
end
