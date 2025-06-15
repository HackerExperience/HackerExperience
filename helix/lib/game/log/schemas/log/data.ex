defmodule Game.Log.Data do
  defmodule EmptyData do
    use Game.Log.Data.Definition
    defstruct []

    def spec do
      selection(
        schema(%{
          __openapi_name: "LogDataEmpty"
        }),
        []
      )
    end

    def new(m) when map_size(m) == 0, do: %__MODULE__{}
    def dump!(%__MODULE__{}), do: %{}
    def load!(_), do: %__MODULE__{}
    def cast_input!(%{}), do: new(%{})
    def valid?(_), do: true
    def render(_), do: %{}
  end

  defmodule Text do
    use Game.Log.Data.Definition
    defstruct [:text]

    def spec do
      selection(
        schema(%{
          __openapi_name: "LogDataText",
          text: binary()
        }),
        [:text]
      )
    end

    def new(%{text: text}), do: %__MODULE__{text: text}
    def dump!(%__MODULE__{text: text}), do: %{text: text}
    def load!(%{text: text}), do: %__MODULE__{text: text}
    def cast_input!(raw_input), do: %__MODULE__{text: raw_input["text"]}
    def valid?(%__MODULE__{text: _text}), do: true
    def render(%__MODULE__{text: text}), do: %{text: text}
  end

  defmodule NIP do
    use Game.Log.Data.Definition
    alias Core.NIP
    defstruct [:nip]

    def spec do
      selection(
        schema(%{
          __openapi_name: "LogDataNIP",
          nip: nip()
        }),
        [:nip]
      )
    end

    def new(%{nip: %NIP{} = nip}), do: %__MODULE__{nip: nip}
    def dump!(%__MODULE__{nip: nip}), do: %{nip: NIP.to_internal(nip)}
    def load!(%{nip: raw_nip}), do: %__MODULE__{nip: NIP.from_internal(raw_nip)}

    def cast_input!(raw_input) do
      %__MODULE__{
        nip: NIP.parse_external!(raw_input["nip"])
      }
    end

    def valid?(%__MODULE__{nip: _nip}) do
      # NIP is validated during parsing
      true
    end

    def render(%__MODULE__{nip: nip}) do
      %{nip: NIP.to_external(nip)}
    end
  end

  defmodule NIPProxy do
    use Game.Log.Data.Definition
    alias Core.NIP
    defstruct [:from_nip, :to_nip]

    def spec do
      selection(
        schema(%{
          __openapi_name: "LogDataNIPProxy",
          from_nip: nip(),
          to_nip: nip()
        }),
        [:from_nip, :to_nip]
      )
    end

    def new(%{from_nip: %NIP{} = from, to_nip: %NIP{} = to}),
      do: %__MODULE__{from_nip: from, to_nip: to}

    def dump!(%__MODULE__{from_nip: from, to_nip: to}),
      do: %{from_nip: NIP.to_internal(from), to_nip: NIP.to_internal(to)}

    def load!(%{from_nip: raw_from, to_nip: raw_to}),
      do: %__MODULE__{from_nip: NIP.from_internal(raw_from), to_nip: NIP.from_internal(raw_to)}

    def cast_input!(raw_input) do
      %__MODULE__{
        from_nip: NIP.parse_external!(raw_input["from_nip"]),
        to_nip: NIP.parse_external!(raw_input["to_nip"])
      }
    end

    def valid?(%__MODULE__{from_nip: from_nip, to_nip: to_nip}) do
      # NIPs are validated during parsing
      from_nip != to_nip
    end

    def render(%__MODULE__{from_nip: from_nip, to_nip: to_nip}) do
      %{from_nip: NIP.to_external(from_nip), to_nip: NIP.to_external(to_nip)}
    end
  end

  defmodule LocalFile do
    use Game.Log.Data.Definition
    alias Game.File
    defstruct [:file_name, :file_ext, :file_version]

    def spec do
      selection(
        schema(%{
          __openapi_name: "LogDataLocalFile",
          file_name: binary(),
          file_ext: binary(),
          file_version: integer()
        }),
        [:file_name, :file_ext, :file_version]
      )
    end

    def new(%{file: %File{} = file}),
      do: %__MODULE__{file_name: file.name, file_ext: "todo", file_version: file.version}

    def dump!(%__MODULE__{} = data),
      do: Map.from_struct(data)

    def load!(entry),
      do: struct(__MODULE__, entry)

    def cast_input!(raw_input) do
      %__MODULE__{
        file_name: raw_input["file_name"] || "",
        file_ext: raw_input["file_ext"] || "",
        file_version: raw_input["file_version"] || 0
      }
    end

    def valid?(%__MODULE__{file_name: file_name, file_ext: file_ext, file_version: file_version}) do
      with true <- File.Validator.validate_name(file_name),
           true <- File.Validator.validate_extension(file_ext),
           true <- File.Validator.validate_version(file_version) do
        true
      else
        _ ->
          false
      end
    end

    def render(%__MODULE__{} = data) do
      %{
        file_name: data.file_name,
        file_ext: data.file_ext,
        file_version: data.file_version
      }
    end
  end

  defmodule RemoteFile do
    use Game.Log.Data.Definition
    alias Core.NIP
    alias Game.File
    defstruct [:nip, :file_name, :file_ext, :file_version]

    def spec do
      selection(
        schema(%{
          __openapi_name: "LogDataRemoteFile",
          nip: nip(),
          file_name: binary(),
          file_ext: binary(),
          file_version: integer()
        }),
        [:nip, :file_name, :file_ext, :file_version]
      )
    end

    def new(%{nip: %NIP{} = nip, file: %File{} = file}),
      do: %__MODULE__{nip: nip, file_name: file.name, file_ext: "todo", file_version: file.version}

    def dump!(%__MODULE__{} = data) do
      data
      |> Map.from_struct()
      |> Map.put(:nip, NIP.to_internal(data.nip))
    end

    def load!(entry) do
      entry
      |> Map.put(:nip, NIP.from_internal(entry.nip))
      |> then(&struct(__MODULE__, &1))
    end

    def cast_input!(raw_input) do
      %__MODULE__{
        nip: NIP.parse_external!(raw_input["nip"]),
        file_name: raw_input["file_name"] || "",
        file_ext: raw_input["file_ext"] || "",
        file_version: raw_input["file_version"] || 0
      }
    end

    def valid?(%__MODULE__{} = data) do
      # NIP is validated during parsing

      with true <- File.Validator.validate_name(data.file_name),
           true <- File.Validator.validate_extension(data.file_ext),
           true <- File.Validator.validate_version(data.file_version) do
        true
      else
        _ ->
          false
      end
    end

    def render(%__MODULE__{} = data) do
      %{
        nip: NIP.to_external(data.nip),
        file_name: data.file_name,
        file_ext: data.file_ext,
        file_version: data.file_version
      }
    end
  end
end
