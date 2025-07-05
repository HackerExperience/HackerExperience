defmodule Game.Endpoint.AppStore.InstallTest do
  use Test.WebCase, async: true

  alias Game.{Server, Software}

  setup [:with_game_db, :with_game_webserver]

  describe "AppStore.Install request" do
    test "successfully starts an AppStoreInstallProcess", %{jwt: jwt, player: player} do
      %{server: server} = Setup.server(entity_id: player.id)
      DB.commit()

      assert {:ok, %{status: 200, data: data}} =
               post(build_path(server.id, :cracker, player.id), %{}, token: jwt)

      # The AppStoreInstallProcess was started
      assert data.process.process_id
      assert data.process.type == "appstore_install"

      assert [registry] = U.get_all_process_registries()
      assert registry.process_id == data.process.process_id |> U.from_eid(player.id)
      assert registry.entity_id.id == player.id.id
      assert registry.server_id == server.id

      assert [process] = U.get_all_processes(server.id)
      assert process.type == :appstore_install
      assert process.data.software_type == :cracker

      # Emits a ProcessCreatedEvent
      assert [process_created_event] = wait_events_on_server!(server.id, :process_created)
      assert process_created_event.name == :process_created
      assert process_created_event.data.process.id == process.id
      assert process_created_event.data.process.data.software_type == :cracker
    end

    test "succeeds if there's a matching installation but no file", %{jwt: jwt, player: player} do
      %{server: server} = Setup.server(entity_id: player.id)
      appstore_config = Software.get!(:cracker).config.appstore

      # Create a matching File and Installation
      file =
        Setup.file!(server.id, type: :cracker, version: appstore_config.version, installed?: true)

      DB.commit()

      # Delete the matching File
      Core.with_context(:server, server.id, :write, fn ->
        DB.delete(file)
      end)

      assert {:ok, %{status: 200, data: data}} =
               post(build_path(server.id, :cracker, player.id), %{}, token: jwt)

      # The AppStoreInstallProcess was started
      assert data.process.process_id
      assert data.process.type == "appstore_install"
    end

    test "succeeds if there's a matching file but no installation", %{jwt: jwt, player: player} do
      %{server: server} = Setup.server(entity_id: player.id)
      appstore_config = Software.get!(:cracker).config.appstore

      # Create a matching File that isn't installed
      Setup.file!(server.id, type: :cracker, version: appstore_config.version)

      DB.commit()

      assert {:ok, %{status: 200, data: data}} =
               post(build_path(server.id, :cracker, player.id), %{}, token: jwt)

      # The AppStoreInstallProcess was started
      assert data.process.process_id
      assert data.process.type == "appstore_install"
    end

    test "succeeds if there are non-matching File and Installations", %{jwt: jwt, player: player} do
      %{server: server} = Setup.server(entity_id: player.id)
      appstore_config = Software.get!(:cracker).config.appstore

      # Create an "almost matching" File and Installation -- missed the version by 1!
      Setup.file(server.id, type: :cracker, version: appstore_config.version + 1, installed?: true)
      DB.commit()

      assert {:ok, %{status: 200, data: data}} =
               post(build_path(server.id, :cracker, player.id), %{}, token: jwt)

      # The AppStoreInstallProcess was started
      assert data.process.process_id
      assert data.process.type == "appstore_install"
    end

    test "fails if there is a matching File and Installation", %{jwt: jwt, player: player} do
      %{server: server} = Setup.server(entity_id: player.id)

      # Create a matching file and installation for cracker
      appstore_config = Software.get!(:cracker).config.appstore
      Setup.file(server.id, type: :cracker, version: appstore_config.version, installed?: true)
      DB.commit()

      assert {:error, %{status: 400, error: %{msg: reason}}} =
               post(build_path(server.id, :cracker, player.id), %{}, token: jwt)

      assert reason == "file_already_installed"
    end

    test "fails if software type is not appstore installable", %{jwt: jwt, player: player} do
      %{server: server} = Setup.server(entity_id: player.id)
      DB.commit()

      assert {:error, %{status: 400, error: %{msg: reason}}} =
               post(build_path(server.id, :log_editor, player.id), %{}, token: jwt)

      assert reason == "invalid_input"
    end

    test "fails if trying to install on someone else's server", %{jwt: jwt, player: player} do
      # The server exists, but belongs to someone else.
      other_server = Setup.server!()
      DB.commit()

      assert {:error, %{status: 400, error: %{msg: reason}}} =
               post(build_path(other_server.id, :cracker, player.id), %{}, token: jwt)

      assert reason == "server_not_found"
    end

    test "fails if trying to install on a non-existing server", %{jwt: jwt, player: player} do
      # Server with ID 999 does not exist
      assert {:error, %{status: 400, error: %{msg: reason}}} =
               post(build_path(%Server.ID{id: 999}, :cracker, player.id), %{}, token: jwt)

      assert reason == "server_not_found"
    end
  end

  defp build_path(%Server.ID{} = server_id, software_type, player_id) do
    server_eid = ID.to_external(server_id, player_id)
    "/server/#{server_eid}/appstore/#{software_type}/install"
  end
end
