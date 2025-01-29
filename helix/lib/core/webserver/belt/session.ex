defmodule Core.Webserver.Belt.Session do
  @env Mix.env()

  # TODO: Maybe convert the session and session.data maps in proper structs

  alias Feeb.DB
  alias Webserver.Conveyor
  alias Core.Crypto
  alias Game.Services, as: Svc
  alias Game.{Entity}

  def call(request, conveyor, _) do
    # Maybe move the session_for_* functions to a Session module? Easier to test
    cond do
      is_sse_request?(request) ->
        session_for_sse_endpoint(request)

      is_request_on_public_endpoint?(request) ->
        {:ok, session_for_public_endpoint(request)}

      true ->
        session_for_private_endpoint(request)
    end
    |> case do
      {:ok, session} ->
        %{request | session: session}

      {:error, reason} when is_binary(reason) or is_atom(reason) ->
        Conveyor.halt_with_response(request, conveyor, 400, "#{reason}")
    end
  end

  defp is_sse_request?(%{xargs: %{sse: true}}), do: true
  defp is_sse_request?(_), do: false

  defp is_request_on_public_endpoint?(%{xargs: %{public: true}}), do: true
  defp is_request_on_public_endpoint?(_), do: false

  defp session_for_public_endpoint(request) do
    shard_id = get_shard_id_for_universe(request)
    %{type: :public, universe: request.universe, shard_id: shard_id, data: nil}
  end

  defp session_for_sse_endpoint(request) do
    shard_id = get_shard_id_for_universe(request)

    case parse_jwt(request.raw_params["token"]) do
      {:ok, %{session_id: session_id, external_id: external_id}} ->
        DB.begin(request.universe, shard_id, :read)

        session_data =
          case Svc.Player.fetch(by_external_id: external_id) do
            %{} = player ->
              DB.commit()

              entity_id = Entity.ID.new(player.id)
              Process.put(:helix_session_entity_id, entity_id)

              %{
                type: :authenticated,
                player_id: player.id,
                entity_id: entity_id,
                external_id: player.external_id
              }

            nil ->
              %{type: :unauthenticated, external_id: external_id}
          end

        {:ok,
         %{
           id: session_id,
           type: :sse,
           universe: request.universe,
           shard_id: shard_id,
           data: session_data
         }}

      {:error, _reason} = error ->
        error
    end
  end

  # TODO: Cover this with (explicit) tests
  defp session_for_private_endpoint(%{cowboy_request: cowboy_request} = request) do
    shard_id = get_shard_id_for_universe(request)

    with {:ok, claims} <- parse_jwt(cowboy_request.headers["authorization"]),
         DB.begin(request.universe, shard_id, :read),
         %{} = player <- Svc.Player.fetch(by_external_id: claims.external_id) || :user_not_found do
      DB.commit()

      entity_id = Entity.ID.new(player.id)
      Process.put(:helix_session_entity_id, entity_id)

      session_data = %{
        type: :authenticated,
        player_id: player.id,
        entity_id: entity_id,
        external_id: player.external_id
      }

      {:ok,
       %{id: claims.session_id, universe: request.universe, shard_id: shard_id, data: session_data}}
    else
      :user_not_found ->
        raise "User not found"

      {:error, :missing_token} ->
        raise "Invalid token"
    end
  end

  if @env == :test do
    defp get_shard_id_for_universe(%{universe: :lobby} = request),
      do: get_shard_id_for_test(request, "test-lobby-shard-id")

    defp get_shard_id_for_universe(%{universe: u} = req) when u in [:singleplayer, :multiplayer],
      do: get_shard_id_for_test(req, "test-game-shard-id")

    defp get_shard_id_for_test(request, header_name) do
      # Each test runs their own shard, which should be defined in the following header
      case Map.get(request.cowboy_request.headers, header_name) do
        raw_shard_id when is_binary(raw_shard_id) ->
          String.to_integer(raw_shard_id)

        nil ->
          raise "Missing `#{header_name}` header"
      end
    end
  else
    defp get_shard_id_for_universe(%{universe: u}) when u in [:lobby, :singleplayer, :multiplayer],
      do: 1
  end

  defp parse_jwt(nil), do: {:error, :missing_token}

  defp parse_jwt(token) when is_binary(token) do
    case Crypto.JWT.verify(token) do
      {true, %JOSE.JWT{fields: raw_claims}, %JOSE.JWS{alg: {:jose_jws_alg_hmac, :HS256}}} ->
        iat = Map.fetch!(raw_claims, "iat")
        external_id = Map.fetch!(raw_claims, "uid")

        claims = %{
          session_id: "#{external_id}_#{iat}",
          iat: iat,
          external_id: external_id
        }

        {:ok, claims}

      _ ->
        {:error, :invalid_token}
    end
  end
end
