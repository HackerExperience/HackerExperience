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
end
