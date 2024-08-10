# NOTE: It probably makes sense to move this to Core and have the same Contextualization
# belt in both Lobby/SP/MP/etc...
defmodule Lobby.Webserver.Belt.Contextualization do
  @env Mix.env()

  def call(request, _, _) do
    # TODO
    session =
      if true do
        session_for_public_endpoint(request)
      else
        session_for_private_endpoint(request)
      end

    %{request | session: session}
  end

  defp session_for_public_endpoint(request) do
    type = :public
    db_context = get_db_context_on_public_endpoint(request.endpoint)
    shard_id = get_shard_id_for_context(db_context, request)

    %{type: type, db_context: db_context, shard_id: shard_id}
  end

  defp session_for_private_endpoint(_request) do
    # NOTE: This module may need a wild refactor once we actually implement auth
    # for private endpoints. The way it's currently structured will lead to
    # code duplication

    raise "TODO"
  end

  defp get_db_context_on_public_endpoint(endpoint) do
    # TODO (also, this is now `universe` and set elsewhere, no?)
    case Module.split(endpoint) do
      ["Lobby" | _] -> :lobby
      _ -> :multiplayer
    end
  end

  defp get_shard_id_for_context(:lobby, request) do
    if @env != :test do
      # In prod/dev, there is a single Lobby shard (1).
      1
    else
      # Each test runs their own shard of lobby, which should be defined in the
      # following header.
      case Map.get(request.cowboy_request.headers, "test-lobby-shard-id") do
        raw_shard_id when is_binary(raw_shard_id) ->
          String.to_integer(raw_shard_id)

        nil ->
          raise "Missing `test-lobby-shard-id` header"
      end
    end
  end

  defp get_shard_id_for_context(:multiplayer, _) do
    # TODO
    1
  end
end
