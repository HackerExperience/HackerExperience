defmodule Game.Henforcers.AppStore do
  alias Core.Henforcer
  alias Game.Services, as: Svc
  alias Game.Henforcers

  @doc """
  Determines whether the provided `file_type` can be AppStore-installed in the target server.

  It can be AppStore-installed if:

  - `file_type` is installable.
  - One of the following conditions is true:
    a. "AppStore software" is not already present and installed in the server; or
    b. "AppStore software" is present in the server but not installed; or
    c. "AppStore software" is not present in the server but installed.
  - In the event of the File being added to the server, the server must have sufficient storage.
  - In the event of the File being installed, the server must have sufficient memory.

  Notes:

  By "AppStore software" we mean the exact combination between file type and version.

  It is at this moment (Henforcer check) that we determine if the resulting process should:
  - Download & install software; or
  - Only download software; or
  - Only install software.
  """
  def can_install?(server, file_type) do
    with {true, %{software: software}} <- Henforcers.Software.type_appstore_installable?(file_type),
         {:ok, action, matching_files_relay} <- infer_appstore_action(server, software),
         {:ok, action_relay} <- henforce_appstore_action(server, software, action) do
      relay =
        %{software: software, action: action}
        |> Map.merge(matching_files_relay)
        |> Map.merge(action_relay)

      Henforcer.success(relay)
    else
      {:error, reason} ->
        Henforcer.fail(reason)

      {false, _, _} = henforcer_error ->
        henforcer_error
    end
  end

  defp infer_appstore_action(server, software) do
    params = {software.type, software.config.appstore[:version] || 10}

    matching_files = Svc.File.list(server.id, by_type_and_version: params)
    matching_installations = Svc.Installation.list(server.id, by_file_type_and_version: params)
    relay = %{matching_files: matching_files, matching_installations: matching_installations}

    case {matching_files, matching_installations} do
      {[], []} ->
        {:ok, :download_and_install, relay}

      {_, []} ->
        {:ok, :install_only, relay}

      {[], _} ->
        {:ok, :download_only, relay}

      {_, _} ->
        {:error, {:appstore_action, :already_installed}}
    end
  end

  defp henforce_appstore_action(_server, _software, action) do
    _henforcers =
      case action do
        :download_and_install ->
          [:sufficient_memory, :sufficient_storage]

        :download_only ->
          [:sufficient_storage]

        :install_only ->
          [:sufficient_memory]
      end

    # TODO: Iterate over henforcers and accumulate their relay

    {:ok, %{}}
  end
end
