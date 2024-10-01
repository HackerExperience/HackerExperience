module Effect exposing (..)

-- Type

import API.Lobby as LobbyAPI
import API.Types exposing (InputConfig)
import Task exposing (Task)
import UUID exposing (Seeds)
import Utils


type Effect msg
    = None
    | Batch (List (Effect msg))
    | APIRequest (APIRequestEnum msg)
    | MsgToCmd msg


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

        MsgToCmd msg ->
            ( seeds, Utils.msgToCmd msg )


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


lobbyLogin : (API.Types.LobbyLoginResult -> msg) -> InputConfig API.Types.LobbyLoginBody -> Effect msg
lobbyLogin msg config =
    APIRequest (LobbyLogin msg config)


msgToCmd : msg -> Effect msg
msgToCmd msg =
    MsgToCmd msg



-- Map


map : (a -> msg) -> Effect a -> Effect msg
map toMsg effect =
    case effect of
        None ->
            None

        Batch effects ->
            Batch (List.map (map toMsg) effects)

        MsgToCmd msg ->
            MsgToCmd (toMsg msg)

        APIRequest apiRequestType ->
            case apiRequestType of
                LobbyLogin msg body ->
                    APIRequest (LobbyLogin (\result -> toMsg (msg result)) body)
