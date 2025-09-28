defmodule Test.Setup.Process.Spec do
  use Test.Setup.Definition

  alias Game.Process.Executable
  alias Game.{Software}

  alias Game.Process.AppStore.Install, as: AppStoreInstallProcess
  alias Game.Process.File.Delete, as: FileDeleteProcess
  alias Game.Process.File.Install, as: FileInstallProcess
  alias Game.Process.File.Transfer, as: FileTransferProcess
  alias Game.Process.Installation.Uninstall, as: InstallationUninstallProcess
  alias Game.Process.Log.Delete, as: LogDeleteProcess
  alias Game.Process.Log.Edit, as: LogEditProcess
  alias Game.Process.Server.Login, as: ServerLoginProcess
  alias Test.Process.NoopCPU, as: NoopCPUProcess
  alias Test.Process.NoopDLK, as: NoopDLKProcess

  @implementations [
    :appstore_install,
    :file_delete,
    :file_install,
    :file_transfer,
    :installation_uninstall,
    :log_delete,
    :log_edit,
    :server_login
  ]

  @doc """
  Grabs a random (non-test) implementation type.
  """
  def random_type do
    @implementations
    |> Enum.take_random(1)
    |> List.first()
  end

  def spec(:noop_cpu, server_id, entity_id, _opts),
    do: build_spec(NoopCPUProcess, server_id, entity_id, %{}, %{}, %{})

  def spec(:noop_dlk, server_id, entity_id, _opts),
    do: build_spec(NoopDLKProcess, server_id, entity_id, %{}, %{}, %{})

  def spec(:appstore_install, server_id, entity_id, opts) do
    software_type = opts[:software_type] || :cracker

    default_meta = %{software: Software.get!(software_type)}
    default_params = %{}

    params = opts[:params] || default_params
    meta = opts[:meta] || default_meta
    relay = %{}

    build_spec(AppStoreInstallProcess, server_id, entity_id, params, meta, relay)
  end

  def spec(:file_delete, server_id, entity_id, opts) do
    file = opts[:file] || S.file!(server_id, visible_by: entity_id)

    default_meta = %{file: file, tunnel: opts[:tunnel]}
    default_params = %{}

    params = opts[:params] || default_params
    meta = opts[:meta] || default_meta
    relay = %{file: file}

    build_spec(FileDeleteProcess, server_id, entity_id, params, meta, relay)
  end

  def spec(:file_install, server_id, entity_id, opts) do
    file = opts[:file] || S.file!(server_id, visible_by: entity_id)

    default_meta = %{file: file}
    default_params = %{}

    params = opts[:params] || default_params
    meta = opts[:meta] || default_meta
    relay = %{file: file}

    build_spec(FileInstallProcess, server_id, entity_id, params, meta, relay)
  end

  def spec(:file_transfer, gateway_id, entity_id, opts) do
    transfer_type = opts[:transfer_type] || Enum.random([:download, :upload])

    endpoint = opts[:endpoint] || S.server!()

    gtw_nip = Svc.NetworkConnection.fetch!(by_server_id: gateway_id).nip
    endp_nip = Svc.NetworkConnection.fetch!(by_server_id: endpoint.id).nip

    file_server_id =
      case transfer_type do
        :download -> endpoint.id
        :upload -> gateway_id
      end

    file = opts[:file] || S.file!(file_server_id, visible_by: entity_id)

    tunnel =
      opts[:tunnel] || S.tunnel!(source_nip: gtw_nip, target_nip: endp_nip, hops: opts[:hops] || [])

    params =
      %{
        transfer_type: transfer_type,
        endpoint: endpoint
      }

    meta =
      %{
        file: file,
        tunnel: tunnel
      }

    relay = %{file: file, tunnel: tunnel, endpoint: endpoint, transfer_type: transfer_type}

    build_spec(FileTransferProcess, gateway_id, entity_id, params, meta, relay)
  end

  def spec(:installation_uninstall, server_id, entity_id, opts) do
    {installation, file} =
      case {opts[:installation], opts[:file]} do
        {%_{} = installation, file} ->
          {installation, file}

        {nil, _} ->
          %{installation: installation, file: file} =
            S.file(server_id, visible_by: entity_id, installed?: true)

          {installation, file}
      end

    default_meta = %{installation: installation}
    default_params = %{}

    params = opts[:params] || default_params
    meta = opts[:meta] || default_meta
    relay = %{installation: installation, file: file}

    build_spec(InstallationUninstallProcess, server_id, entity_id, params, meta, relay)
  end

  def spec(:log_delete, server_id, entity_id, opts) do
    default_params = %{}

    default_meta = fn ->
      log = opts[:log] || S.log!(server_id, visible_by: entity_id)
      tunnel = opts[:tunnel] || nil

      %{log: log, tunnel: tunnel}
    end

    params = opts[:params] || default_params
    meta = opts[:meta] || default_meta.()

    build_spec(LogDeleteProcess, server_id, entity_id, params, meta, %{})
  end

  def spec(:log_edit, server_id, entity_id, opts) do
    default_params = fn ->
      # This is actually TODO; it should come from a Setup.Log.Data util
      {log_type, direction, log_data} =
        opts[:log_info] || {:server_login, :self, %Game.Log.Data.EmptyData{}}

      %{type: log_type, direction: direction, data: log_data}
    end

    default_meta = fn ->
      log = opts[:log] || S.log!(server_id)
      %{log: log}
    end

    params = opts[:params] || default_params.()
    meta = opts[:meta] || default_meta.()

    build_spec(LogEditProcess, server_id, entity_id, params, meta, %{})
  end

  def spec(:server_login, server_id, entity_id, opts) do
    %{nip: gtw_nip} = Svc.NetworkConnection.fetch!(by_server_id: server_id)

    {endpoint, target_nip} =
      cond do
        endpoint = opts[:endpoint] ->
          %{nip: endp_nip} = Svc.NetworkConnection.fetch!(by_server_id: endpoint.id)
          {endpoint, endp_nip}

        target_nip = opts[:target_nip] ->
          {nil, target_nip}

        true ->
          %{server: endpoint, nip: endp_nip} = S.server()
          {endpoint, endp_nip}
      end

    params =
      %{
        source_nip: gtw_nip,
        target_nip: target_nip,
        tunnel_id: opts[:tunnel_id],
        vpn_id: opts[:vpn_id]
      }

    meta = %{}

    relay = %{endpoint: endpoint, target_nip: target_nip}

    build_spec(ServerLoginProcess, server_id, entity_id, params, meta, relay)
  end

  defp build_spec(mod, server_id, entity_id, params, meta, relay) do
    executable = Module.concat(mod, :Executable)

    {registry_data, process_info} =
      Executable.get_registry_params(executable, [server_id, entity_id, params, meta])

    %{
      module: mod,
      type: mod.get_process_type(params, meta),
      data: mod.new(params, meta),
      params: params,
      meta: meta,
      server_id: server_id,
      entity_id: entity_id,
      registry_data: registry_data,
      process_info: process_info
    }
    |> Map.merge(relay)
  end
end
