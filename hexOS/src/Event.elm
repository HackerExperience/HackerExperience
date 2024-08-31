module Event exposing (..)

import API.Events.Json as Events
import API.Events.Types as Events
import Json.Decode as JD
import Result


type Event
    = IndexRequested Events.IndexRequested



-- TODO: Maybe in the future I could add a non-Elm CI check that ensures that every type
-- defined in API.Events.Types is present in this file twice


processReceivedEvent : String -> Result JD.Error Event
processReceivedEvent rawEvent =
    JD.decodeString eventDecoder rawEvent


eventDecoder : JD.Decoder Event
eventDecoder =
    JD.field "name" JD.string
        |> JD.andThen dataDecoder


dataDecoder : String -> JD.Decoder Event
dataDecoder eventName =
    let
        innerDataDecoder =
            case eventName of
                "index_requested" ->
                    JD.map (\x -> IndexRequested x)
                        Events.decodeIndexRequested

                _ ->
                    JD.fail "Invalid event"
    in
    JD.map (\data -> data)
        (JD.field "data" innerDataDecoder)
