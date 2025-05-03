-- This is an auto-generated file; manual changes will be overwritten!


module API.Game.Json exposing
    ( encodeFileDeleteInput, encodeFileDeleteOkResponse, encodeFileDeleteOutput, encodeFileDeleteRequest
    , encodeFileInstallInput, encodeFileInstallOkResponse, encodeFileInstallOutput, encodeFileInstallRequest
    , encodeFileTransferInput, encodeFileTransferOkResponse, encodeFileTransferOutput, encodeFileTransferRequest
    , encodeGenericBadRequest, encodeGenericBadRequestResponse, encodeGenericError, encodeGenericErrorResponse
    , encodeGenericUnauthorizedResponse, encodeInstallationUninstallInput, encodeInstallationUninstallOkResponse
    , encodeInstallationUninstallOutput, encodeInstallationUninstallRequest, encodeLogDeleteInput
    , encodeLogDeleteOkResponse, encodeLogDeleteOutput, encodeLogDeleteRequest, encodeLogEditInput
    , encodeLogEditOkResponse, encodeLogEditOutput, encodeLogEditRequest, encodePlayerSyncInput
    , encodePlayerSyncOkResponse, encodePlayerSyncOutput, encodePlayerSyncRequest, encodeServerLoginInput
    , encodeServerLoginOkResponse, encodeServerLoginOutput, encodeServerLoginRequest
    , decodeFileDeleteInput, decodeFileDeleteOkResponse, decodeFileDeleteOutput, decodeFileDeleteRequest
    , decodeFileInstallInput, decodeFileInstallOkResponse, decodeFileInstallOutput, decodeFileInstallRequest
    , decodeFileTransferInput, decodeFileTransferOkResponse, decodeFileTransferOutput, decodeFileTransferRequest
    , decodeGenericBadRequest, decodeGenericBadRequestResponse, decodeGenericError, decodeGenericErrorResponse
    , decodeGenericUnauthorizedResponse, decodeInstallationUninstallInput, decodeInstallationUninstallOkResponse
    , decodeInstallationUninstallOutput, decodeInstallationUninstallRequest, decodeLogDeleteInput
    , decodeLogDeleteOkResponse, decodeLogDeleteOutput, decodeLogDeleteRequest, decodeLogEditInput
    , decodeLogEditOkResponse, decodeLogEditOutput, decodeLogEditRequest, decodePlayerSyncInput
    , decodePlayerSyncOkResponse, decodePlayerSyncOutput, decodePlayerSyncRequest, decodeServerLoginInput
    , decodeServerLoginOkResponse, decodeServerLoginOutput, decodeServerLoginRequest
    )

{-|


## Encoders

@docs encodeFileDeleteInput, encodeFileDeleteOkResponse, encodeFileDeleteOutput, encodeFileDeleteRequest
@docs encodeFileInstallInput, encodeFileInstallOkResponse, encodeFileInstallOutput, encodeFileInstallRequest
@docs encodeFileTransferInput, encodeFileTransferOkResponse, encodeFileTransferOutput, encodeFileTransferRequest
@docs encodeGenericBadRequest, encodeGenericBadRequestResponse, encodeGenericError, encodeGenericErrorResponse
@docs encodeGenericUnauthorizedResponse, encodeInstallationUninstallInput, encodeInstallationUninstallOkResponse
@docs encodeInstallationUninstallOutput, encodeInstallationUninstallRequest, encodeLogDeleteInput
@docs encodeLogDeleteOkResponse, encodeLogDeleteOutput, encodeLogDeleteRequest, encodeLogEditInput
@docs encodeLogEditOkResponse, encodeLogEditOutput, encodeLogEditRequest, encodePlayerSyncInput
@docs encodePlayerSyncOkResponse, encodePlayerSyncOutput, encodePlayerSyncRequest, encodeServerLoginInput
@docs encodeServerLoginOkResponse, encodeServerLoginOutput, encodeServerLoginRequest


## Decoders

@docs decodeFileDeleteInput, decodeFileDeleteOkResponse, decodeFileDeleteOutput, decodeFileDeleteRequest
@docs decodeFileInstallInput, decodeFileInstallOkResponse, decodeFileInstallOutput, decodeFileInstallRequest
@docs decodeFileTransferInput, decodeFileTransferOkResponse, decodeFileTransferOutput, decodeFileTransferRequest
@docs decodeGenericBadRequest, decodeGenericBadRequestResponse, decodeGenericError, decodeGenericErrorResponse
@docs decodeGenericUnauthorizedResponse, decodeInstallationUninstallInput, decodeInstallationUninstallOkResponse
@docs decodeInstallationUninstallOutput, decodeInstallationUninstallRequest, decodeLogDeleteInput
@docs decodeLogDeleteOkResponse, decodeLogDeleteOutput, decodeLogDeleteRequest, decodeLogEditInput
@docs decodeLogEditOkResponse, decodeLogEditOutput, decodeLogEditRequest, decodePlayerSyncInput
@docs decodePlayerSyncOkResponse, decodePlayerSyncOutput, decodePlayerSyncRequest, decodeServerLoginInput
@docs decodeServerLoginOkResponse, decodeServerLoginOutput, decodeServerLoginRequest

-}

import API.Game.Types
import Game.Model.LogID as LogID exposing (LogID(..))
import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ProcessID as ProcessID exposing (ProcessID(..))
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
                (Json.Decode.map TunnelID Json.Decode.string)
            )


encodeServerLoginInput : API.Game.Types.ServerLoginInput -> Json.Encode.Value
encodeServerLoginInput rec =
    Json.Encode.object
        (List.filterMap
            Basics.identity
            [ Maybe.map
                (\mapUnpack -> ( "tunnel_id", Json.Encode.string (TunnelID.toValue mapUnpack) ))
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


decodeLogEditOutput : Json.Decode.Decoder API.Game.Types.LogEditOutput
decodeLogEditOutput =
    Json.Decode.succeed {}


encodeLogEditOutput : API.Game.Types.LogEditOutput -> Json.Encode.Value
encodeLogEditOutput rec =
    Json.Encode.object []


decodeLogEditInput : Json.Decode.Decoder API.Game.Types.LogEditInput
decodeLogEditInput =
    Json.Decode.succeed
        (\tunnel_id -> { tunnel_id = tunnel_id })
        |> OpenApi.Common.jsonDecodeAndMap
            (OpenApi.Common.decodeOptionalField
                "tunnel_id"
                (Json.Decode.map TunnelID Json.Decode.string)
            )


encodeLogEditInput : API.Game.Types.LogEditInput -> Json.Encode.Value
encodeLogEditInput rec =
    Json.Encode.object
        (List.filterMap
            Basics.identity
            [ Maybe.map
                (\mapUnpack -> ( "tunnel_id", Json.Encode.string (TunnelID.toValue mapUnpack) ))
                rec.tunnel_id
            ]
        )


decodeLogDeleteOutput : Json.Decode.Decoder API.Game.Types.LogDeleteOutput
decodeLogDeleteOutput =
    Json.Decode.succeed {}


encodeLogDeleteOutput : API.Game.Types.LogDeleteOutput -> Json.Encode.Value
encodeLogDeleteOutput rec =
    Json.Encode.object []


decodeLogDeleteInput : Json.Decode.Decoder API.Game.Types.LogDeleteInput
decodeLogDeleteInput =
    Json.Decode.succeed
        (\tunnel_id -> { tunnel_id = tunnel_id })
        |> OpenApi.Common.jsonDecodeAndMap
            (OpenApi.Common.decodeOptionalField
                "tunnel_id"
                (Json.Decode.map TunnelID Json.Decode.string)
            )


encodeLogDeleteInput : API.Game.Types.LogDeleteInput -> Json.Encode.Value
encodeLogDeleteInput rec =
    Json.Encode.object
        (List.filterMap
            Basics.identity
            [ Maybe.map
                (\mapUnpack -> ( "tunnel_id", Json.Encode.string (TunnelID.toValue mapUnpack) ))
                rec.tunnel_id
            ]
        )


decodeInstallationUninstallOutput : Json.Decode.Decoder API.Game.Types.InstallationUninstallOutput
decodeInstallationUninstallOutput =
    Json.Decode.succeed {}


encodeInstallationUninstallOutput : API.Game.Types.InstallationUninstallOutput -> Json.Encode.Value
encodeInstallationUninstallOutput rec =
    Json.Encode.object []


decodeInstallationUninstallInput : Json.Decode.Decoder API.Game.Types.InstallationUninstallInput
decodeInstallationUninstallInput =
    Json.Decode.succeed {}


encodeInstallationUninstallInput : API.Game.Types.InstallationUninstallInput -> Json.Encode.Value
encodeInstallationUninstallInput rec =
    Json.Encode.object []


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


decodeFileTransferOutput : Json.Decode.Decoder API.Game.Types.FileTransferOutput
decodeFileTransferOutput =
    Json.Decode.succeed {}


encodeFileTransferOutput : API.Game.Types.FileTransferOutput -> Json.Encode.Value
encodeFileTransferOutput rec =
    Json.Encode.object []


decodeFileTransferInput : Json.Decode.Decoder API.Game.Types.FileTransferInput
decodeFileTransferInput =
    Json.Decode.succeed
        (\transfer_type tunnel_id ->
            { transfer_type = transfer_type, tunnel_id = tunnel_id }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "transfer_type" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "tunnel_id"
                (Json.Decode.map TunnelID Json.Decode.string)
            )


encodeFileTransferInput : API.Game.Types.FileTransferInput -> Json.Encode.Value
encodeFileTransferInput rec =
    Json.Encode.object
        [ ( "transfer_type", Json.Encode.string rec.transfer_type )
        , ( "tunnel_id", Json.Encode.string (TunnelID.toValue rec.tunnel_id) )
        ]


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
                (Json.Decode.map TunnelID Json.Decode.string)
            )


encodeFileDeleteInput : API.Game.Types.FileDeleteInput -> Json.Encode.Value
encodeFileDeleteInput rec =
    Json.Encode.object
        (List.filterMap
            Basics.identity
            [ Maybe.map
                (\mapUnpack -> ( "tunnel_id", Json.Encode.string (TunnelID.toValue mapUnpack) ))
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


decodeLogEditOkResponse : Json.Decode.Decoder API.Game.Types.LogEditOkResponse
decodeLogEditOkResponse =
    Json.Decode.succeed
        (\data -> { data = data })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "data"
                decodeLogEditOutput
            )


encodeLogEditOkResponse : API.Game.Types.LogEditOkResponse -> Json.Encode.Value
encodeLogEditOkResponse rec =
    Json.Encode.object [ ( "data", encodeLogEditOutput rec.data ) ]


decodeLogDeleteOkResponse : Json.Decode.Decoder API.Game.Types.LogDeleteOkResponse
decodeLogDeleteOkResponse =
    Json.Decode.succeed
        (\data -> { data = data })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "data"
                decodeLogDeleteOutput
            )


encodeLogDeleteOkResponse : API.Game.Types.LogDeleteOkResponse -> Json.Encode.Value
encodeLogDeleteOkResponse rec =
    Json.Encode.object [ ( "data", encodeLogDeleteOutput rec.data ) ]


decodeInstallationUninstallOkResponse : Json.Decode.Decoder API.Game.Types.InstallationUninstallOkResponse
decodeInstallationUninstallOkResponse =
    Json.Decode.succeed
        (\data -> { data = data })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "data"
                decodeInstallationUninstallOutput
            )


encodeInstallationUninstallOkResponse : API.Game.Types.InstallationUninstallOkResponse -> Json.Encode.Value
encodeInstallationUninstallOkResponse rec =
    Json.Encode.object
        [ ( "data", encodeInstallationUninstallOutput rec.data ) ]


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


decodeFileTransferOkResponse : Json.Decode.Decoder API.Game.Types.FileTransferOkResponse
decodeFileTransferOkResponse =
    Json.Decode.succeed
        (\data -> { data = data })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "data"
                decodeFileTransferOutput
            )


encodeFileTransferOkResponse : API.Game.Types.FileTransferOkResponse -> Json.Encode.Value
encodeFileTransferOkResponse rec =
    Json.Encode.object [ ( "data", encodeFileTransferOutput rec.data ) ]


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


decodeLogEditRequest : Json.Decode.Decoder API.Game.Types.LogEditRequest
decodeLogEditRequest =
    decodeLogEditInput


encodeLogEditRequest : API.Game.Types.LogEditRequest -> Json.Encode.Value
encodeLogEditRequest =
    encodeLogEditInput


decodeLogDeleteRequest : Json.Decode.Decoder API.Game.Types.LogDeleteRequest
decodeLogDeleteRequest =
    decodeLogDeleteInput


encodeLogDeleteRequest : API.Game.Types.LogDeleteRequest -> Json.Encode.Value
encodeLogDeleteRequest =
    encodeLogDeleteInput


decodeInstallationUninstallRequest : Json.Decode.Decoder API.Game.Types.InstallationUninstallRequest
decodeInstallationUninstallRequest =
    decodeInstallationUninstallInput


encodeInstallationUninstallRequest : API.Game.Types.InstallationUninstallRequest -> Json.Encode.Value
encodeInstallationUninstallRequest =
    encodeInstallationUninstallInput


decodeFileTransferRequest : Json.Decode.Decoder API.Game.Types.FileTransferRequest
decodeFileTransferRequest =
    decodeFileTransferInput


encodeFileTransferRequest : API.Game.Types.FileTransferRequest -> Json.Encode.Value
encodeFileTransferRequest =
    encodeFileTransferInput


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
