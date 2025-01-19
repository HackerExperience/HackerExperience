-- This is an auto-generated file; manual changes will be overwritten!


module API.Game.Json exposing
    ( encodeFileDeleteInput, encodeFileDeleteOkResponse, encodeFileDeleteOutput, encodeFileDeleteRequest
    , encodeFileInstallInput, encodeFileInstallOkResponse, encodeFileInstallOutput, encodeFileInstallRequest
    , encodeGenericBadRequest, encodeGenericBadRequestResponse, encodeGenericError, encodeGenericErrorResponse
    , encodeGenericUnauthorizedResponse, encodePlayerSyncInput, encodePlayerSyncOkResponse
    , encodePlayerSyncOutput, encodePlayerSyncRequest, encodeServerLoginInput, encodeServerLoginOkResponse
    , encodeServerLoginOutput, encodeServerLoginRequest
    , decodeFileDeleteInput, decodeFileDeleteOkResponse, decodeFileDeleteOutput, decodeFileDeleteRequest
    , decodeFileInstallInput, decodeFileInstallOkResponse, decodeFileInstallOutput, decodeFileInstallRequest
    , decodeGenericBadRequest, decodeGenericBadRequestResponse, decodeGenericError, decodeGenericErrorResponse
    , decodeGenericUnauthorizedResponse, decodePlayerSyncInput, decodePlayerSyncOkResponse
    , decodePlayerSyncOutput, decodePlayerSyncRequest, decodeServerLoginInput, decodeServerLoginOkResponse
    , decodeServerLoginOutput, decodeServerLoginRequest
    )

{-|


## Encoders

@docs encodeFileDeleteInput, encodeFileDeleteOkResponse, encodeFileDeleteOutput, encodeFileDeleteRequest
@docs encodeFileInstallInput, encodeFileInstallOkResponse, encodeFileInstallOutput, encodeFileInstallRequest
@docs encodeGenericBadRequest, encodeGenericBadRequestResponse, encodeGenericError, encodeGenericErrorResponse
@docs encodeGenericUnauthorizedResponse, encodePlayerSyncInput, encodePlayerSyncOkResponse
@docs encodePlayerSyncOutput, encodePlayerSyncRequest, encodeServerLoginInput, encodeServerLoginOkResponse
@docs encodeServerLoginOutput, encodeServerLoginRequest


## Decoders

@docs decodeFileDeleteInput, decodeFileDeleteOkResponse, decodeFileDeleteOutput, decodeFileDeleteRequest
@docs decodeFileInstallInput, decodeFileInstallOkResponse, decodeFileInstallOutput, decodeFileInstallRequest
@docs decodeGenericBadRequest, decodeGenericBadRequestResponse, decodeGenericError, decodeGenericErrorResponse
@docs decodeGenericUnauthorizedResponse, decodePlayerSyncInput, decodePlayerSyncOkResponse
@docs decodePlayerSyncOutput, decodePlayerSyncRequest, decodeServerLoginInput, decodeServerLoginOkResponse
@docs decodeServerLoginOutput, decodeServerLoginRequest

-}

import API.Game.Types
import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ServerID as ServerID exposing (ServerID(..))
import Game.Model.TunnelID as TunnelID exposing (TunnelID(..))
import Json.Decode
import Json.Encode
import OpenApi.Common


decodeServerLoginOutput : Json.Decode.Decoder API.Game.Types.ServerLoginOutput
decodeServerLoginOutput =
    Json.Decode.succeed {}


encodeServerLoginOutput : API.Game.Types.ServerLoginOutput -> Json.Encode.Value
encodeServerLoginOutput rec =
    Json.Encode.object []


decodeServerLoginInput : Json.Decode.Decoder API.Game.Types.ServerLoginInput
decodeServerLoginInput =
    Json.Decode.succeed
        (\tunnel_id -> { tunnel_id = tunnel_id })
        |> OpenApi.Common.jsonDecodeAndMap
            (OpenApi.Common.decodeOptionalField
                "tunnel_id"
                (Json.Decode.map TunnelID Json.Decode.int)
            )


encodeServerLoginInput : API.Game.Types.ServerLoginInput -> Json.Encode.Value
encodeServerLoginInput rec =
    Json.Encode.object
        (List.filterMap
            Basics.identity
            [ Maybe.map
                (\mapUnpack -> ( "tunnel_id", Json.Encode.int (TunnelID.toValue mapUnpack) ))
                rec.tunnel_id
            ]
        )


decodePlayerSyncOutput : Json.Decode.Decoder API.Game.Types.PlayerSyncOutput
decodePlayerSyncOutput =
    Json.Decode.succeed {}


encodePlayerSyncOutput : API.Game.Types.PlayerSyncOutput -> Json.Encode.Value
encodePlayerSyncOutput rec =
    Json.Encode.object []


decodePlayerSyncInput : Json.Decode.Decoder API.Game.Types.PlayerSyncInput
decodePlayerSyncInput =
    Json.Decode.succeed
        (\token -> { token = token })
        |> OpenApi.Common.jsonDecodeAndMap
            (OpenApi.Common.decodeOptionalField
                "token"
                Json.Decode.string
            )


encodePlayerSyncInput : API.Game.Types.PlayerSyncInput -> Json.Encode.Value
encodePlayerSyncInput rec =
    Json.Encode.object
        (List.filterMap
            Basics.identity
            [ Maybe.map
                (\mapUnpack -> ( "token", Json.Encode.string mapUnpack ))
                rec.token
            ]
        )


decodeGenericError : Json.Decode.Decoder API.Game.Types.GenericError
decodeGenericError =
    Json.Decode.succeed
        (\details msg -> { details = details, msg = msg })
        |> OpenApi.Common.jsonDecodeAndMap
            (OpenApi.Common.decodeOptionalField
                "details"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "msg" Json.Decode.string)


encodeGenericError : API.Game.Types.GenericError -> Json.Encode.Value
encodeGenericError rec =
    Json.Encode.object
        (List.filterMap
            Basics.identity
            [ Maybe.map
                (\mapUnpack -> ( "details", Json.Encode.string mapUnpack ))
                rec.details
            , Just ( "msg", Json.Encode.string rec.msg )
            ]
        )


decodeGenericBadRequest : Json.Decode.Decoder API.Game.Types.GenericBadRequest
decodeGenericBadRequest =
    Json.Decode.succeed
        (\details msg -> { details = details, msg = msg })
        |> OpenApi.Common.jsonDecodeAndMap
            (OpenApi.Common.decodeOptionalField
                "details"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "msg" Json.Decode.string)


encodeGenericBadRequest : API.Game.Types.GenericBadRequest -> Json.Encode.Value
encodeGenericBadRequest rec =
    Json.Encode.object
        (List.filterMap
            Basics.identity
            [ Maybe.map
                (\mapUnpack -> ( "details", Json.Encode.string mapUnpack ))
                rec.details
            , Just ( "msg", Json.Encode.string rec.msg )
            ]
        )


decodeFileInstallOutput : Json.Decode.Decoder API.Game.Types.FileInstallOutput
decodeFileInstallOutput =
    Json.Decode.succeed {}


encodeFileInstallOutput : API.Game.Types.FileInstallOutput -> Json.Encode.Value
encodeFileInstallOutput rec =
    Json.Encode.object []


decodeFileInstallInput : Json.Decode.Decoder API.Game.Types.FileInstallInput
decodeFileInstallInput =
    Json.Decode.succeed {}


encodeFileInstallInput : API.Game.Types.FileInstallInput -> Json.Encode.Value
encodeFileInstallInput rec =
    Json.Encode.object []


decodeFileDeleteOutput : Json.Decode.Decoder API.Game.Types.FileDeleteOutput
decodeFileDeleteOutput =
    Json.Decode.succeed {}


encodeFileDeleteOutput : API.Game.Types.FileDeleteOutput -> Json.Encode.Value
encodeFileDeleteOutput rec =
    Json.Encode.object []


decodeFileDeleteInput : Json.Decode.Decoder API.Game.Types.FileDeleteInput
decodeFileDeleteInput =
    Json.Decode.succeed
        (\tunnel_id -> { tunnel_id = tunnel_id })
        |> OpenApi.Common.jsonDecodeAndMap
            (OpenApi.Common.decodeOptionalField
                "tunnel_id"
                (Json.Decode.map TunnelID Json.Decode.int)
            )


encodeFileDeleteInput : API.Game.Types.FileDeleteInput -> Json.Encode.Value
encodeFileDeleteInput rec =
    Json.Encode.object
        (List.filterMap
            Basics.identity
            [ Maybe.map
                (\mapUnpack -> ( "tunnel_id", Json.Encode.int (TunnelID.toValue mapUnpack) ))
                rec.tunnel_id
            ]
        )


decodeServerLoginOkResponse : Json.Decode.Decoder API.Game.Types.ServerLoginOkResponse
decodeServerLoginOkResponse =
    Json.Decode.succeed
        (\data -> { data = data })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "data"
                decodeServerLoginOutput
            )


encodeServerLoginOkResponse : API.Game.Types.ServerLoginOkResponse -> Json.Encode.Value
encodeServerLoginOkResponse rec =
    Json.Encode.object [ ( "data", encodeServerLoginOutput rec.data ) ]


decodePlayerSyncOkResponse : Json.Decode.Decoder API.Game.Types.PlayerSyncOkResponse
decodePlayerSyncOkResponse =
    Json.Decode.succeed
        (\data -> { data = data })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "data"
                decodePlayerSyncOutput
            )


encodePlayerSyncOkResponse : API.Game.Types.PlayerSyncOkResponse -> Json.Encode.Value
encodePlayerSyncOkResponse rec =
    Json.Encode.object [ ( "data", encodePlayerSyncOutput rec.data ) ]


decodeGenericUnauthorizedResponse : Json.Decode.Decoder API.Game.Types.GenericUnauthorizedResponse
decodeGenericUnauthorizedResponse =
    Json.Decode.succeed ()


encodeGenericUnauthorizedResponse : API.Game.Types.GenericUnauthorizedResponse -> Json.Encode.Value
encodeGenericUnauthorizedResponse rec =
    Json.Encode.null


decodeGenericErrorResponse : Json.Decode.Decoder API.Game.Types.GenericErrorResponse
decodeGenericErrorResponse =
    Json.Decode.succeed
        (\error -> { error = error })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "error"
                decodeGenericError
            )


encodeGenericErrorResponse : API.Game.Types.GenericErrorResponse -> Json.Encode.Value
encodeGenericErrorResponse rec =
    Json.Encode.object [ ( "error", encodeGenericError rec.error ) ]


decodeGenericBadRequestResponse : Json.Decode.Decoder API.Game.Types.GenericBadRequestResponse
decodeGenericBadRequestResponse =
    Json.Decode.succeed
        (\error -> { error = error })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "error"
                decodeGenericBadRequest
            )


encodeGenericBadRequestResponse : API.Game.Types.GenericBadRequestResponse -> Json.Encode.Value
encodeGenericBadRequestResponse rec =
    Json.Encode.object [ ( "error", encodeGenericBadRequest rec.error ) ]


decodeFileInstallOkResponse : Json.Decode.Decoder API.Game.Types.FileInstallOkResponse
decodeFileInstallOkResponse =
    Json.Decode.succeed
        (\data -> { data = data })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "data"
                decodeFileInstallOutput
            )


encodeFileInstallOkResponse : API.Game.Types.FileInstallOkResponse -> Json.Encode.Value
encodeFileInstallOkResponse rec =
    Json.Encode.object [ ( "data", encodeFileInstallOutput rec.data ) ]


decodeFileDeleteOkResponse : Json.Decode.Decoder API.Game.Types.FileDeleteOkResponse
decodeFileDeleteOkResponse =
    Json.Decode.succeed
        (\data -> { data = data })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "data"
                decodeFileDeleteOutput
            )


encodeFileDeleteOkResponse : API.Game.Types.FileDeleteOkResponse -> Json.Encode.Value
encodeFileDeleteOkResponse rec =
    Json.Encode.object [ ( "data", encodeFileDeleteOutput rec.data ) ]


decodeServerLoginRequest : Json.Decode.Decoder API.Game.Types.ServerLoginRequest
decodeServerLoginRequest =
    decodeServerLoginInput


encodeServerLoginRequest : API.Game.Types.ServerLoginRequest -> Json.Encode.Value
encodeServerLoginRequest =
    encodeServerLoginInput


decodePlayerSyncRequest : Json.Decode.Decoder API.Game.Types.PlayerSyncRequest
decodePlayerSyncRequest =
    decodePlayerSyncInput


encodePlayerSyncRequest : API.Game.Types.PlayerSyncRequest -> Json.Encode.Value
encodePlayerSyncRequest =
    encodePlayerSyncInput


decodeFileInstallRequest : Json.Decode.Decoder API.Game.Types.FileInstallRequest
decodeFileInstallRequest =
    decodeFileInstallInput


encodeFileInstallRequest : API.Game.Types.FileInstallRequest -> Json.Encode.Value
encodeFileInstallRequest =
    encodeFileInstallInput


decodeFileDeleteRequest : Json.Decode.Decoder API.Game.Types.FileDeleteRequest
decodeFileDeleteRequest =
    decodeFileDeleteInput


encodeFileDeleteRequest : API.Game.Types.FileDeleteRequest -> Json.Encode.Value
encodeFileDeleteRequest =
    encodeFileDeleteInput
