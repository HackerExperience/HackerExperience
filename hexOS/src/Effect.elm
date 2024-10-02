module Effect exposing (..)

-- Type

import API.Lobby as LobbyAPI
import API.Types exposing (InputConfig)
import Ports
import Task exposing (Task)
import UUID exposing (Seeds)
import Utils


type Effect msg
    = None
    | Batch (List (Effect msg))
    | APIRequest (APIRequestEnum msg)
    | MsgToCmd Float msg
    | StartSSESubscription String


type APIRequestEnum msg
    = LobbyLogin (API.Types.LobbyLoginResult -> msg) (InputConfig API.Types.LobbyLoginBody)



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
            ( seeds, Ports.eventStart token )


applyApiRequest : APIRequestEnum msg -> Seeds -> ( Seeds, Cmd msg )
applyApiRequest apiRequest seeds =
    case apiRequest of
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



-- Effects > API Requests


lobbyLogin : (API.Types.LobbyLoginResult -> msg) -> InputConfig API.Types.LobbyLoginBody -> Effect msg
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
                LobbyLogin msg body ->
                    APIRequest (LobbyLogin (\result -> toMsg (msg result)) body)

        StartSSESubscription token ->
            StartSSESubscription token