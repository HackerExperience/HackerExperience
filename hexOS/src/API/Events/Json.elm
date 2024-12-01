module API.Events.Json exposing
    ( encodeIdxGateway, encodeIdxLog, encodeIdxPlayer, encodeIndexRequested, encodeTunnelCreated
    , decodeIdxGateway, decodeIdxLog, decodeIdxPlayer, decodeIndexRequested, decodeTunnelCreated
    )

{-|


## Encoders

@docs encodeIdxGateway, encodeIdxLog, encodeIdxPlayer, encodeIndexRequested, encodeTunnelCreated


## Decoders

@docs decodeIdxGateway, decodeIdxLog, decodeIdxPlayer, decodeIndexRequested, decodeTunnelCreated

-}

import API.Events.Types
import Json.Decode
import Json.Encode
import OpenApi.Common


decodeTunnelCreated : Json.Decode.Decoder API.Events.Types.TunnelCreated
decodeTunnelCreated =
    Json.Decode.succeed
        (\access source_nip target_nip tunnel_id ->
            { access = access
            , source_nip = source_nip
            , target_nip = target_nip
            , tunnel_id = tunnel_id
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "access" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "source_nip"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "target_nip"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "tunnel_id"
                Json.Decode.string
            )


encodeTunnelCreated : API.Events.Types.TunnelCreated -> Json.Encode.Value
encodeTunnelCreated rec =
    Json.Encode.object
        [ ( "access", Json.Encode.string rec.access )
        , ( "source_nip", Json.Encode.string rec.source_nip )
        , ( "target_nip", Json.Encode.string rec.target_nip )
        , ( "tunnel_id", Json.Encode.string rec.tunnel_id )
        ]


decodeIndexRequested : Json.Decode.Decoder API.Events.Types.IndexRequested
decodeIndexRequested =
    Json.Decode.succeed
        (\player -> { player = player })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "player"
                decodeIdxPlayer
            )


encodeIndexRequested : API.Events.Types.IndexRequested -> Json.Encode.Value
encodeIndexRequested rec =
    Json.Encode.object [ ( "player", encodeIdxPlayer rec.player ) ]


decodeIdxPlayer : Json.Decode.Decoder API.Events.Types.IdxPlayer
decodeIdxPlayer =
    Json.Decode.succeed
        (\gateways mainframe_id ->
            { gateways = gateways, mainframe_id = mainframe_id }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "gateways"
                (Json.Decode.list decodeIdxGateway)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "mainframe_id"
                Json.Decode.int
            )


encodeIdxPlayer : API.Events.Types.IdxPlayer -> Json.Encode.Value
encodeIdxPlayer rec =
    Json.Encode.object
        [ ( "gateways", Json.Encode.list encodeIdxGateway rec.gateways )
        , ( "mainframe_id", Json.Encode.int rec.mainframe_id )
        ]


decodeIdxLog : Json.Decode.Decoder API.Events.Types.IdxLog
decodeIdxLog =
    Json.Decode.succeed
        (\id revision_id type_ ->
            { id = id, revision_id = revision_id, type_ = type_ }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "id" Json.Decode.int)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "revision_id"
                Json.Decode.int
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "type"
                Json.Decode.string
            )


encodeIdxLog : API.Events.Types.IdxLog -> Json.Encode.Value
encodeIdxLog rec =
    Json.Encode.object
        [ ( "id", Json.Encode.int rec.id )
        , ( "revision_id", Json.Encode.int rec.revision_id )
        , ( "type", Json.Encode.string rec.type_ )
        ]


decodeIdxGateway : Json.Decode.Decoder API.Events.Types.IdxGateway
decodeIdxGateway =
    Json.Decode.succeed
        (\id logs -> { id = id, logs = logs })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "id" Json.Decode.int)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "logs"
                (Json.Decode.list decodeIdxLog)
            )


encodeIdxGateway : API.Events.Types.IdxGateway -> Json.Encode.Value
encodeIdxGateway rec =
    Json.Encode.object
        [ ( "id", Json.Encode.int rec.id )
        , ( "logs", Json.Encode.list encodeIdxLog rec.logs )
        ]
