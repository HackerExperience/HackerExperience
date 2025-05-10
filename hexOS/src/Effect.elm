module Effect exposing (..)

-- Type

import API.Game as GameAPI
import API.Lobby as LobbyAPI
import API.Types exposing (InputConfig, InputToken)
import API.Utils
import Browser.Dom
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
    | StartSSESubscription InputToken String
    | DebouncedCmd (Cmd msg)
    | DomFocus String msg


type APIRequestEnum msg
    = LobbyLogin (API.Types.LobbyLoginResult -> msg) (InputConfig API.Types.LobbyLoginInput)
    | LogDelete (API.Types.LogDeleteResult -> msg) (InputConfig API.Types.LogDeleteInput)
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

        StartSSESubscription token baseUrl ->
            let
                encodedValue =
                    JE.object
                        [ ( "token", JE.string <| API.Utils.tokenToString token )
                        , ( "baseUrl", JE.string baseUrl )
                        ]
            in
            ( seeds, Ports.eventStart encodedValue )

        DomFocus domId msg ->
            ( seeds, Task.attempt (\_ -> msg) (Browser.Dom.focus domId) )

        -- The `elm-debounce` library always returns a Cmd. We are merely wrapping it into an Effect
        DebouncedCmd cmd ->
            ( seeds, cmd )


applyApiRequest : APIRequestEnum msg -> Seeds -> ( Seeds, Cmd msg )
applyApiRequest apiRequest seeds =
    case apiRequest of
        -- Game
        LogDelete msg config ->
            ( seeds, Task.attempt msg (GameAPI.logDeleteTask config) )

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


sseStart : InputToken -> String -> Effect msg
sseStart token baseUrl =
    StartSSESubscription token baseUrl


debouncedCmd : Cmd msg -> Effect msg
debouncedCmd cmd =
    DebouncedCmd cmd


domFocus : String -> msg -> Effect msg
domFocus domId msg =
    DomFocus domId msg



-- Effects > API Requests > Game
-- Log


logDelete : (API.Types.LogDeleteResult -> msg) -> InputConfig API.Types.LogDeleteInput -> Effect msg
logDelete msg config =
    APIRequest (LogDelete msg config)



-- Server


serverLogin : (API.Types.ServerLoginResult -> msg) -> InputConfig API.Types.ServerLoginInput -> Effect msg
serverLogin msg config =
    APIRequest (ServerLogin msg config)



-- Effects > API Requests > Lobby


lobbyLogin : (API.Types.LobbyLoginResult -> msg) -> InputConfig API.Types.LobbyLoginInput -> Effect msg
lobbyLogin msg config =
    APIRequest (LobbyLogin msg config)



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

                LogDelete msg body ->
                    APIRequest (LogDelete (\result -> toMsg (msg result)) body)

                -- Lobby
                LobbyLogin msg body ->
                    APIRequest (LobbyLogin (\result -> toMsg (msg result)) body)

        StartSSESubscription token baseUrl ->
            StartSSESubscription token baseUrl

        DebouncedCmd cmd ->
            DebouncedCmd (Cmd.map toMsg cmd)

        DomFocus domId msg ->
            DomFocus domId (toMsg msg)
