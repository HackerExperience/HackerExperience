module Event exposing
    ( Event(..)
    , processReceivedEvent
    )

import API.Events.Json as Events
import API.Events.Types as Events
import Game.Model.NIP as NIP exposing (NIP)
import Json.Decode as JD



-- TODO: Where do I scope the Universe? In the Event type itself?


type Event
    = IndexRequested Events.IndexRequested
    | TunnelCreated Events.TunnelCreated



-- TODO: Maybe in the future I could add a non-Elm CI check that ensures that every type
-- defined in API.Events.Types is present in this file twice


processReceivedEvent : JD.Value -> Result JD.Error Event
processReceivedEvent event =
    JD.decodeValue eventDecoder event


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

                "tunnel_created" ->
                    JD.map (\x -> TunnelCreated x)
                        Events.decodeTunnelCreated

                name ->
                    JD.fail <| "Unexpected event: " ++ name
    in
    JD.field "data" innerDataDecoder
