module Event exposing
    ( Event(..)
    , processReceivedEvent
    )

import API.Events.Json as Events
import API.Events.Types as Events
import Game.Universe as Universe exposing (Universe)
import Json.Decode as JD


type Event
    = IndexRequested Events.IndexRequested Universe
    | AppStoreInstalled Events.AppstoreInstalled Universe
    | FileDeleted Events.FileDeleted Universe
    | FileInstalled Events.FileInstalled Universe
    | LogDeleted Events.LogDeleted Universe
    | LogEdited Events.LogEdited Universe
    | ProcessCompleted Events.ProcessCompleted Universe
    | ProcessCreated Events.ProcessCreated Universe
    | TunnelCreated Events.TunnelCreated Universe



-- TODO: Maybe in the future I could add a non-Elm CI check that ensures that every type
-- defined in API.Events.Types is present in this file twice


processReceivedEvent : JD.Value -> Result JD.Error Event
processReceivedEvent event =
    JD.decodeValue eventDecoder event


eventDecoder : JD.Decoder Event
eventDecoder =
    JD.field "universe" JD.string
        |> JD.andThen universeDecoder


universeDecoder : String -> JD.Decoder Event
universeDecoder rawUniverse =
    let
        ( isUniverseValid, universe ) =
            Universe.isUniverseStringValid rawUniverse
    in
    if isUniverseValid then
        JD.field "name" JD.string
            |> JD.andThen (dataDecoder universe)

    else
        JD.fail <| "Invalid universe string: " ++ rawUniverse


dataDecoder : Universe -> String -> JD.Decoder Event
dataDecoder universe eventName =
    let
        innerDataDecoder =
            case eventName of
                "index_requested" ->
                    JD.map (\x -> IndexRequested x universe)
                        Events.decodeIndexRequested

                "appstore_installed" ->
                    JD.map (\x -> AppStoreInstalled x universe)
                        Events.decodeAppstoreInstalled

                "file_deleted" ->
                    JD.map (\x -> FileDeleted x universe)
                        Events.decodeFileDeleted

                "file_installed" ->
                    JD.map (\x -> FileInstalled x universe)
                        Events.decodeFileInstalled

                "log_deleted" ->
                    JD.map (\x -> LogDeleted x universe)
                        Events.decodeLogDeleted

                "log_edited" ->
                    JD.map (\x -> LogEdited x universe)
                        Events.decodeLogEdited

                "process_completed" ->
                    JD.map (\x -> ProcessCompleted x universe)
                        Events.decodeProcessCompleted

                "process_created" ->
                    JD.map (\x -> ProcessCreated x universe)
                        Events.decodeProcessCreated

                "tunnel_created" ->
                    JD.map (\x -> TunnelCreated x universe)
                        Events.decodeTunnelCreated

                name ->
                    JD.fail <| "Unexpected event: " ++ name
    in
    JD.field "data" innerDataDecoder
