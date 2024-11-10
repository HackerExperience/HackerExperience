defmodule Core.NIP do
  @behaviour Feeb.DB.Type.Behaviour

  require Logger

  defstruct [:network_id, :ip]

  @type t :: %__MODULE__{
          network_id: integer(),
          ip: String.t()
        }

  @doc """
  TODO
  """
  def from_external(str_nip) when is_binary(str_nip) do
    # TODO: Validate that values are valid
    [raw_network_id, raw_ip] = String.split(str_nip, "@")
    %__MODULE__{network_id: String.to_integer(raw_network_id), ip: raw_ip}
  end

  @doc """
  TODO
  """
  def to_external(%__MODULE__{network_id: network_id, ip: ip}),
    do: "#{network_id}@#{ip}"

  @impl true
  def sqlite_type, do: :text

  @impl true
  def cast!(str_nip, _, _) when is_binary(str_nip), do: from_external(str_nip)
  def cast!(%__MODULE__{} = nip, _, _), do: nip

  @impl true
  def dump!(%__MODULE__{} = nip, _, _), do: to_internal(nip)

  @impl true
  def load!(internal_nip, _, _) when is_binary(internal_nip), do: from_internal(internal_nip)

  # The "internal" format is used when storing the NIP in the database. We invert the order of the
  # components in order to improve cache cardinality. As soon as data is retrieved from DB, we
  # convert it back `from_internal/1`. Similarly, right before writing to disk, we convert it
  # `to_internal/1`.
  def to_internal(%__MODULE__{network_id: network_id, ip: ip}),
    do: "#{ip}@#{network_id}"

  defp from_internal(internal_nip) when is_binary(internal_nip) do
    [raw_ip, raw_network_id] = String.split(internal_nip, "@")
    %__MODULE__{network_id: String.to_integer(raw_network_id), ip: raw_ip}
  end

  defimpl String.Chars do
    def to_string(%_{} = nip), do: Core.NIP.to_internal(nip)
  end
end
