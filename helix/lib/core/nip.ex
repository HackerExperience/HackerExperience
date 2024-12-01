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
  def parse_external(str_nip) when is_binary(str_nip) do
    with [raw_network_id, raw_ip] <- String.split(str_nip, "@"),
         {:ok, network_id} <- parse_external_network_id(raw_network_id),
         {:ok, ip} <- parse_external_ip(raw_ip) do
      {:ok, %__MODULE__{network_id: network_id, ip: ip}}
    else
      {:error, _} = error ->
        error

      _ ->
        {:error, :invalid_nip}
    end
  end

  def parse_external!(str_nip) when is_binary(str_nip) do
    {:ok, nip} = parse_external(str_nip)
    nip
  end

  @doc """
  TODO
  """
  def to_external(%__MODULE__{network_id: network_id, ip: ip}),
    do: "#{network_id}@#{ip}"

  def to_external(nil), do: ""

  @impl true
  def sqlite_type, do: :text

  @impl true
  def cast!(str_nip, _, _) when is_binary(str_nip), do: unsafe_from_external!(str_nip)
  def cast!(%__MODULE__{} = nip, _, _), do: nip
  def cast!(nil, %{nullable: true}, _), do: nil

  @impl true
  def dump!(%__MODULE__{} = nip, _, _), do: to_internal(nip)
  def dump!(nil, _, _), do: nil

  @impl true
  def load!(internal_nip, _, _) when is_binary(internal_nip), do: from_internal(internal_nip)
  def load!(nil, %{nullable: true}, _), do: nil

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

  defp parse_external_network_id(raw_network_id) when is_binary(raw_network_id) do
    try do
      {:ok, String.to_integer(raw_network_id)}
    rescue
      ArgumentError ->
        {:error, {:invalid_network_id, raw_network_id}}
    end
  end

  defp parse_external_ip(raw_ip) do
    if Renatils.IP.valid?(raw_ip) do
      {:ok, raw_ip}
    else
      {:error, {:invalid_ip, raw_ip}}
    end
  end

  # Unsafe. Use only when retrieving from disk (which is assumed to be stored correctly)
  defp unsafe_from_external!(str_nip) do
    [raw_network_id, raw_ip] = String.split(str_nip, "@")
    %__MODULE__{network_id: String.to_integer(raw_network_id), ip: raw_ip}
  end

  defimpl String.Chars do
    def to_string(%_{} = nip), do: Core.NIP.to_internal(nip)
  end
end
