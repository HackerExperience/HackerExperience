module API.Events.Json exposing
    ( encodeIndexRequested
    , decodeIndexRequested
    )

{-|


## Encoders

@docs encodeIndexRequested


## Decoders

@docs decodeIndexRequested

-}

import API.Events.Types
import Json.Decode
import Json.Encode
import OpenApi.Common


decodeIndexRequested : Json.Decode.Decoder API.Events.Types.IndexRequested
decodeIndexRequested =
    Json.Decode.succeed
        (\foo -> { foo = foo })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "foo"
                Json.Decode.string
            )


encodeIndexRequested : API.Events.Types.IndexRequested -> Json.Encode.Value
encodeIndexRequested rec =
    Json.Encode.object [ ( "foo", Json.Encode.string rec.foo ) ]
