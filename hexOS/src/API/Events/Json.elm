module API.Events.Json exposing
    ( encodeIdxPlayer, encodeIndexRequested
    , decodeIdxPlayer, decodeIndexRequested
    )

{-|


## Encoders

@docs encodeIdxPlayer, encodeIndexRequested


## Decoders

@docs decodeIdxPlayer, decodeIndexRequested

-}

import API.Events.Types
import Json.Decode
import Json.Encode
import OpenApi.Common


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
        (\mainframe_id -> { mainframe_id = mainframe_id })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "mainframe_id" Json.Decode.int)


encodeIdxPlayer : API.Events.Types.IdxPlayer -> Json.Encode.Value
encodeIdxPlayer rec =
    Json.Encode.object [ ( "mainframe_id", Json.Encode.int rec.mainframe_id ) ]
