module Event exposing
    ( Event(..)
    , processReceivedEvent
    )

import API.Events.Json as Events
import API.Events.Types as Events
import Game.Model.NIP as NIP exposing (NIP)
import Json.Decode as JD



-- TODO: Where do I scope the Universe? In the Event type itself?


type RawEvent
    = RawIndexRequested Events.IndexRequested
    | RawTunnelCreated Events.TunnelCreated


type alias TunnelCreatedData =
    { access : String
    , sourceNip : NIP
    , targetNip : NIP
    , tunnelId : Int
    }



-- TODO: I'd rather fork the elm-open-api library so it generates my custom types there, otherwise I'll
-- have to re-define every event for custom types...


type Event
    = IndexRequested Events.IndexRequested
    | TunnelCreated TunnelCreatedData



-- TODO: Maybe in the future I could add a non-Elm CI check that ensures that every type
-- defined in API.Events.Types is present in this file twice


processReceivedEvent : JD.Value -> Result JD.Error Event
processReceivedEvent rawEvent =
    JD.decodeValue eventDecoder rawEvent
        |> toInternalFormat


eventDecoder : JD.Decoder RawEvent
eventDecoder =
    JD.field "name" JD.string
        |> JD.andThen dataDecoder


dataDecoder : String -> JD.Decoder RawEvent
dataDecoder eventName =
    let
        innerDataDecoder =
            case eventName of
                "index_requested" ->
                    JD.map (\x -> RawIndexRequested x)
                        Events.decodeIndexRequested

                "tunnel_created" ->
                    JD.map (\x -> RawTunnelCreated x)
                        Events.decodeTunnelCreated

                name ->
                    JD.fail <| "Unexpected event: " ++ name
    in
    JD.field "data" innerDataDecoder


toInternalFormat : Result JD.Error RawEvent -> Result JD.Error Event
toInternalFormat result =
    case result of
        Ok rawEvent ->
            Ok (fromRawEvent rawEvent)

        Err error ->
            Err error


fromRawEvent : RawEvent -> Event
fromRawEvent rawEvent =
    case rawEvent of
        RawIndexRequested data ->
            IndexRequested data

        RawTunnelCreated data ->
            TunnelCreated
                { access = data.access
                , sourceNip = NIP.fromString data.source_nip
                , targetNip = NIP.fromString data.target_nip
                , tunnelId = data.tunnel_id
                }
