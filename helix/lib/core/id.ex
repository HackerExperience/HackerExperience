defmodule Core.ID do
  @type external :: binary()
  @type internal :: integer()

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
end
