-- This is an auto-generated file; manual changes will be overwritten!


module API.Processes.Json exposing
    ( encodeAppstoreInstall, encodeFileDelete, encodeFileInstall, encodeFileTransfer
    , encodeInstallationUninstall, encodeLogDelete, encodeLogEdit, encodeScannerEdit, encodeServerLogin
    , decodeAppstoreInstall, decodeFileDelete, decodeFileInstall, decodeFileTransfer
    , decodeInstallationUninstall, decodeLogDelete, decodeLogEdit, decodeScannerEdit, decodeServerLogin
    )

{-|


## Encoders

@docs encodeAppstoreInstall, encodeFileDelete, encodeFileInstall, encodeFileTransfer
@docs encodeInstallationUninstall, encodeLogDelete, encodeLogEdit, encodeScannerEdit, encodeServerLogin


## Decoders

@docs decodeAppstoreInstall, decodeFileDelete, decodeFileInstall, decodeFileTransfer
@docs decodeInstallationUninstall, decodeLogDelete, decodeLogEdit, decodeScannerEdit, decodeServerLogin

-}

import API.Processes.Types
import Game.Model.FileID as FileID exposing (FileID(..))
import Game.Model.InstallationID as InstallationID exposing (InstallationID(..))
import Game.Model.LogID as LogID exposing (LogID(..))
import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ProcessID as ProcessID exposing (ProcessID(..))
import Game.Model.ServerID as ServerID exposing (ServerID(..))
import Game.Model.TunnelID as TunnelID exposing (TunnelID(..))
import Json.Decode
import Json.Encode
import OpenApi.Common


decodeServerLogin : Json.Decode.Decoder API.Processes.Types.ServerLogin
decodeServerLogin =
    Json.Decode.succeed {}


encodeServerLogin : API.Processes.Types.ServerLogin -> Json.Encode.Value
encodeServerLogin rec =
    Json.Encode.object []


decodeScannerEdit : Json.Decode.Decoder API.Processes.Types.ScannerEdit
decodeScannerEdit =
    Json.Decode.succeed
        (\instance_id -> { instance_id = instance_id })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "instance_id" Json.Decode.string)


encodeScannerEdit : API.Processes.Types.ScannerEdit -> Json.Encode.Value
encodeScannerEdit rec =
    Json.Encode.object [ ( "instance_id", Json.Encode.string rec.instance_id ) ]


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


decodeAppstoreInstall : Json.Decode.Decoder API.Processes.Types.AppstoreInstall
decodeAppstoreInstall =
    Json.Decode.succeed
        (\software_type -> { software_type = software_type })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "software_type" Json.Decode.string)


encodeAppstoreInstall : API.Processes.Types.AppstoreInstall -> Json.Encode.Value
encodeAppstoreInstall rec =
    Json.Encode.object
        [ ( "software_type", Json.Encode.string rec.software_type ) ]
