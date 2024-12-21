defmodule Game.Log.Data do
  defmodule EmptyData do
    defstruct []
    def new(m) when map_size(m) == 0, do: %__MODULE__{}
    def dump!(%__MODULE__{}), do: %{}
    def load!(_), do: %__MODULE__{}
  end

  defmodule NIP do
    alias Core.NIP
    defstruct [:nip]

    def new(%{nip: %NIP{} = nip}), do: %__MODULE__{nip: nip}
    def dump!(%__MODULE__{nip: nip}), do: %{nip: NIP.to_internal(nip)}
    def load!(%{nip: raw_nip}), do: %__MODULE__{nip: NIP.from_internal(raw_nip)}
  end

  defmodule NIPProxy do
    alias Core.NIP
    defstruct [:from_nip, :to_nip]

    def new(%{from_nip: %NIP{} = from, to_nip: %NIP{} = to}),
      do: %__MODULE__{from_nip: from, to_nip: to}

    def dump!(%__MODULE__{from_nip: from, to_nip: to}),
      do: %{from_nip: NIP.to_internal(from), to_nip: NIP.to_internal(to)}

    def load!(%{from_nip: raw_from, to_nip: raw_to}),
      do: %__MODULE__{from_nip: NIP.from_internal(raw_from), to_nip: NIP.from_internal(raw_to)}
  end
end
