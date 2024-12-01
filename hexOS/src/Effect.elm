module Effect exposing (..)

-- Type

import API.Game as GameAPI
import API.Lobby as LobbyAPI
import API.Types exposing (InputConfig)
import Json.Encode as JE
import Ports
import Task
import UUID exposing (Seeds)
import Utils


type Effect msg
    = None
    | Batch (List (Effect msg))
    | APIRequest (APIRequestEnum msg)
    | MsgToCmd Float msg
    | StartSSESubscription String
    | DebouncedCmd (Cmd msg)


type APIRequestEnum msg
    = LobbyLogin (API.Types.LobbyLoginResult -> msg) (InputConfig API.Types.LobbyLoginInput)
    | ServerLogin (API.Types.ServerLoginResult -> msg) (InputConfig API.Types.ServerLoginInput)



-- Implementation


apply : ( Seeds, Effect msg ) -> ( Seeds, Cmd msg )
apply ( seeds, effect ) =
    case effect of
        None ->
            ( seeds, Cmd.none )

        Batch effects ->
            List.foldl batchEffect ( seeds, [] ) effects
                |> Tuple.mapSecond Cmd.batch

        APIRequest requestType ->
            applyApiRequest requestType seeds

        MsgToCmd delay msg ->
            -- TODO: maybe remove Utils call and implement `msgToCmd[WithDelay]` here, directly
            if delay == 0.0 then
                ( seeds, Utils.msgToCmd msg )

            else
                ( seeds, Utils.msgToCmdWithDelay delay msg )

        StartSSESubscription token ->
            ( seeds, Ports.eventStart (JE.string token) )

        -- The `elm-debounce` library always returns a Cmd. We are merely wrapping it into an Effect
        DebouncedCmd cmd ->
            ( seeds, cmd )


applyApiRequest : APIRequestEnum msg -> Seeds -> ( Seeds, Cmd msg )
applyApiRequest apiRequest seeds =
    case apiRequest of
        -- Game
        ServerLogin msg config ->
            ( seeds, Task.attempt msg (GameAPI.serverLoginTask config) )

        -- Lobby
        LobbyLogin msg config ->
            ( seeds, Task.attempt msg (LobbyAPI.loginTask config) )


batchEffect : Effect msg -> ( Seeds, List (Cmd msg) ) -> ( Seeds, List (Cmd msg) )
batchEffect effect ( seeds, cmds ) =
    apply ( seeds, effect )
        |> Tuple.mapSecond (\cmd -> cmd :: cmds)



-- Effects


none : Effect msg
none =
    None


batch : List (Effect msg) -> Effect msg
batch =
    Batch


msgToCmd : msg -> Effect msg
msgToCmd msg =
    MsgToCmd 0.0 msg


msgToCmdWithDelay : Float -> msg -> Effect msg
msgToCmdWithDelay delay msg =
    MsgToCmd delay msg


sseStart : String -> Effect msg
sseStart token =
    StartSSESubscription token


debouncedCmd : Cmd msg -> Effect msg
debouncedCmd cmd =
    DebouncedCmd cmd



-- Effects > API Requests


lobbyLogin : (API.Types.LobbyLoginResult -> msg) -> InputConfig API.Types.LobbyLoginInput -> Effect msg
lobbyLogin msg config =
    APIRequest (LobbyLogin msg config)


serverLogin : (API.Types.ServerLoginResult -> msg) -> InputConfig API.Types.ServerLoginInput -> Effect msg
serverLogin msg config =
    APIRequest (ServerLogin msg config)



-- Map


map : (a -> msg) -> Effect a -> Effect msg
map toMsg effect =
    case effect of
        None ->
            None

        Batch effects ->
            Batch (List.map (map toMsg) effects)

        MsgToCmd delay msg ->
            MsgToCmd delay (toMsg msg)

        APIRequest apiRequestType ->
            case apiRequestType of
                -- Game
                ServerLogin msg body ->
                    APIRequest (ServerLogin (\result -> toMsg (msg result)) body)

                -- Lobby
                LobbyLogin msg body ->
                    APIRequest (LobbyLogin (\result -> toMsg (msg result)) body)

        StartSSESubscription token ->
            StartSSESubscription token

        DebouncedCmd cmd ->
            DebouncedCmd (Cmd.map toMsg cmd)
