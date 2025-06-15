-- This is an auto-generated file; manual changes will be overwritten!


module API.Processes.Json exposing
    ( encodeFileDelete, encodeFileInstall, encodeFileTransfer, encodeInstallationUninstall, encodeLogDelete
    , encodeLogEdit
    , decodeFileDelete, decodeFileInstall, decodeFileTransfer, decodeInstallationUninstall, decodeLogDelete
    , decodeLogEdit
    )

{-|


## Encoders

@docs encodeFileDelete, encodeFileInstall, encodeFileTransfer, encodeInstallationUninstall, encodeLogDelete
@docs encodeLogEdit


## Decoders

@docs decodeFileDelete, decodeFileInstall, decodeFileTransfer, decodeInstallationUninstall, decodeLogDelete
@docs decodeLogEdit

-}

import API.Processes.Types
import Game.Model.LogID as LogID exposing (LogID(..))
import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ProcessID as ProcessID exposing (ProcessID(..))
import Game.Model.TunnelID as TunnelID exposing (TunnelID(..))
import Json.Decode
import Json.Encode
import OpenApi.Common


decodeLogEdit : Json.Decode.Decoder API.Processes.Types.LogEdit
decodeLogEdit =
    Json.Decode.succeed
        (\log_id -> { log_id = log_id })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "log_id"
                (Json.Decode.map LogID Json.Decode.string)
            )


encodeLogEdit : API.Processes.Types.LogEdit -> Json.Encode.Value
encodeLogEdit rec =
    Json.Encode.object [ ( "log_id", Json.Encode.string (LogID.toValue rec.log_id) ) ]


decodeLogDelete : Json.Decode.Decoder API.Processes.Types.LogDelete
decodeLogDelete =
    Json.Decode.succeed
        (\log_id -> { log_id = log_id })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "log_id"
                (Json.Decode.map LogID Json.Decode.string)
            )


encodeLogDelete : API.Processes.Types.LogDelete -> Json.Encode.Value
encodeLogDelete rec =
    Json.Encode.object [ ( "log_id", Json.Encode.string (LogID.toValue rec.log_id) ) ]


decodeInstallationUninstall : Json.Decode.Decoder API.Processes.Types.InstallationUninstall
decodeInstallationUninstall =
    Json.Decode.succeed {}


encodeInstallationUninstall : API.Processes.Types.InstallationUninstall -> Json.Encode.Value
encodeInstallationUninstall rec =
    Json.Encode.object []


decodeFileTransfer : Json.Decode.Decoder API.Processes.Types.FileTransfer
decodeFileTransfer =
    Json.Decode.succeed {}


encodeFileTransfer : API.Processes.Types.FileTransfer -> Json.Encode.Value
encodeFileTransfer rec =
    Json.Encode.object []


decodeFileInstall : Json.Decode.Decoder API.Processes.Types.FileInstall
decodeFileInstall =
    Json.Decode.succeed {}


encodeFileInstall : API.Processes.Types.FileInstall -> Json.Encode.Value
encodeFileInstall rec =
    Json.Encode.object []


decodeFileDelete : Json.Decode.Decoder API.Processes.Types.FileDelete
decodeFileDelete =
    Json.Decode.succeed {}


encodeFileDelete : API.Processes.Types.FileDelete -> Json.Encode.Value
encodeFileDelete rec =
    Json.Encode.object []
