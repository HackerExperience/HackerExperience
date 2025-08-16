-- This is an auto-generated file; manual changes will be overwritten!


module API.Events.Json exposing
    ( encodeAppstoreInstallFailed, encodeAppstoreInstalled, encodeFileDeleteFailed, encodeFileDeleted
    , encodeFileInstallFailed, encodeFileInstalled, encodeFileTransferFailed, encodeFileTransferred
    , encodeIdxEndpoint, encodeIdxFile, encodeIdxGateway, encodeIdxInstallation, encodeIdxLog
    , encodeIdxLogRevision, encodeIdxPlayer, encodeIdxProcess, encodeIdxSoftware, encodeIdxTunnel
    , encodeIndexRequested, encodeInstallationUninstallFailed, encodeInstallationUninstalled
    , encodeLogDeleteFailed, encodeLogDeleted, encodeLogEditFailed, encodeLogEdited, encodeProcessCompleted
    , encodeProcessCreated, encodeProcessKilled, encodeSoftwareConfig, encodeSoftwareConfigAppstore
    , encodeSoftwareManifest, encodeTunnelCreated
    , decodeAppstoreInstallFailed, decodeAppstoreInstalled, decodeFileDeleteFailed, decodeFileDeleted
    , decodeFileInstallFailed, decodeFileInstalled, decodeFileTransferFailed, decodeFileTransferred
    , decodeIdxEndpoint, decodeIdxFile, decodeIdxGateway, decodeIdxInstallation, decodeIdxLog
    , decodeIdxLogRevision, decodeIdxPlayer, decodeIdxProcess, decodeIdxSoftware, decodeIdxTunnel
    , decodeIndexRequested, decodeInstallationUninstallFailed, decodeInstallationUninstalled
    , decodeLogDeleteFailed, decodeLogDeleted, decodeLogEditFailed, decodeLogEdited, decodeProcessCompleted
    , decodeProcessCreated, decodeProcessKilled, decodeSoftwareConfig, decodeSoftwareConfigAppstore
    , decodeSoftwareManifest, decodeTunnelCreated
    )

{-|


## Encoders

@docs encodeAppstoreInstallFailed, encodeAppstoreInstalled, encodeFileDeleteFailed, encodeFileDeleted
@docs encodeFileInstallFailed, encodeFileInstalled, encodeFileTransferFailed, encodeFileTransferred
@docs encodeIdxEndpoint, encodeIdxFile, encodeIdxGateway, encodeIdxInstallation, encodeIdxLog
@docs encodeIdxLogRevision, encodeIdxPlayer, encodeIdxProcess, encodeIdxSoftware, encodeIdxTunnel
@docs encodeIndexRequested, encodeInstallationUninstallFailed, encodeInstallationUninstalled
@docs encodeLogDeleteFailed, encodeLogDeleted, encodeLogEditFailed, encodeLogEdited, encodeProcessCompleted
@docs encodeProcessCreated, encodeProcessKilled, encodeSoftwareConfig, encodeSoftwareConfigAppstore
@docs encodeSoftwareManifest, encodeTunnelCreated


## Decoders

@docs decodeAppstoreInstallFailed, decodeAppstoreInstalled, decodeFileDeleteFailed, decodeFileDeleted
@docs decodeFileInstallFailed, decodeFileInstalled, decodeFileTransferFailed, decodeFileTransferred
@docs decodeIdxEndpoint, decodeIdxFile, decodeIdxGateway, decodeIdxInstallation, decodeIdxLog
@docs decodeIdxLogRevision, decodeIdxPlayer, decodeIdxProcess, decodeIdxSoftware, decodeIdxTunnel
@docs decodeIndexRequested, decodeInstallationUninstallFailed, decodeInstallationUninstalled
@docs decodeLogDeleteFailed, decodeLogDeleted, decodeLogEditFailed, decodeLogEdited, decodeProcessCompleted
@docs decodeProcessCreated, decodeProcessKilled, decodeSoftwareConfig, decodeSoftwareConfigAppstore
@docs decodeSoftwareManifest, decodeTunnelCreated

-}

import API.Events.Types
import Game.Model.FileID as FileID exposing (FileID(..))
import Game.Model.LogID as LogID exposing (LogID(..))
import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ProcessID as ProcessID exposing (ProcessID(..))
import Game.Model.ServerID as ServerID exposing (ServerID(..))
import Game.Model.TunnelID as TunnelID exposing (TunnelID(..))
import Json.Decode
import Json.Encode
import OpenApi.Common


decodeTunnelCreated : Json.Decode.Decoder API.Events.Types.TunnelCreated
decodeTunnelCreated =
    Json.Decode.succeed
        (\access index source_nip target_nip tunnel_id ->
            { access = access
            , index = index
            , source_nip = source_nip
            , target_nip = target_nip
            , tunnel_id = tunnel_id
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "access" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "index" decodeIdxEndpoint)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "source_nip"
                (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "target_nip"
                (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "tunnel_id"
                (Json.Decode.map TunnelID Json.Decode.string)
            )


encodeTunnelCreated : API.Events.Types.TunnelCreated -> Json.Encode.Value
encodeTunnelCreated rec =
    Json.Encode.object
        [ ( "access", Json.Encode.string rec.access )
        , ( "index", encodeIdxEndpoint rec.index )
        , ( "source_nip", Json.Encode.string (NIP.toString rec.source_nip) )
        , ( "target_nip", Json.Encode.string (NIP.toString rec.target_nip) )
        , ( "tunnel_id", Json.Encode.string (TunnelID.toValue rec.tunnel_id) )
        ]


decodeProcessKilled : Json.Decode.Decoder API.Events.Types.ProcessKilled
decodeProcessKilled =
    Json.Decode.succeed
        (\process_id reason -> { process_id = process_id, reason = reason })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "process_id" (Json.Decode.map ProcessID Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "reason" Json.Decode.string)


encodeProcessKilled : API.Events.Types.ProcessKilled -> Json.Encode.Value
encodeProcessKilled rec =
    Json.Encode.object
        [ ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        , ( "reason", Json.Encode.string rec.reason )
        ]


decodeProcessCreated : Json.Decode.Decoder API.Events.Types.ProcessCreated
decodeProcessCreated =
    Json.Decode.succeed
        (\data nip process_id type_ ->
            { data = data, nip = nip, process_id = process_id, type_ = type_ }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "data" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "nip" (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "process_id"
                (Json.Decode.map ProcessID Json.Decode.string)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "type"
                Json.Decode.string
            )


encodeProcessCreated : API.Events.Types.ProcessCreated -> Json.Encode.Value
encodeProcessCreated rec =
    Json.Encode.object
        [ ( "data", Json.Encode.string rec.data )
        , ( "nip", Json.Encode.string (NIP.toString rec.nip) )
        , ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        , ( "type", Json.Encode.string rec.type_ )
        ]


decodeProcessCompleted : Json.Decode.Decoder API.Events.Types.ProcessCompleted
decodeProcessCompleted =
    Json.Decode.succeed
        (\data nip process_id type_ ->
            { data = data, nip = nip, process_id = process_id, type_ = type_ }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "data" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "nip" (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "process_id"
                (Json.Decode.map ProcessID Json.Decode.string)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "type"
                Json.Decode.string
            )


encodeProcessCompleted : API.Events.Types.ProcessCompleted -> Json.Encode.Value
encodeProcessCompleted rec =
    Json.Encode.object
        [ ( "data", Json.Encode.string rec.data )
        , ( "nip", Json.Encode.string (NIP.toString rec.nip) )
        , ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        , ( "type", Json.Encode.string rec.type_ )
        ]


decodeLogEdited : Json.Decode.Decoder API.Events.Types.LogEdited
decodeLogEdited =
    Json.Decode.succeed
        (\data direction log_id nip process_id type_ ->
            { data = data
            , direction = direction
            , log_id = log_id
            , nip = nip
            , process_id = process_id
            , type_ = type_
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "data" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "direction"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "log_id"
                (Json.Decode.map LogID Json.Decode.string)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "nip"
                (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "process_id"
                (Json.Decode.map ProcessID Json.Decode.string)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "type"
                Json.Decode.string
            )


encodeLogEdited : API.Events.Types.LogEdited -> Json.Encode.Value
encodeLogEdited rec =
    Json.Encode.object
        [ ( "data", Json.Encode.string rec.data )
        , ( "direction", Json.Encode.string rec.direction )
        , ( "log_id", Json.Encode.string (LogID.toValue rec.log_id) )
        , ( "nip", Json.Encode.string (NIP.toString rec.nip) )
        , ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        , ( "type", Json.Encode.string rec.type_ )
        ]


decodeLogEditFailed : Json.Decode.Decoder API.Events.Types.LogEditFailed
decodeLogEditFailed =
    Json.Decode.succeed
        (\process_id reason -> { process_id = process_id, reason = reason })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "process_id" (Json.Decode.map ProcessID Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "reason" Json.Decode.string)


encodeLogEditFailed : API.Events.Types.LogEditFailed -> Json.Encode.Value
encodeLogEditFailed rec =
    Json.Encode.object
        [ ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        , ( "reason", Json.Encode.string rec.reason )
        ]


decodeLogDeleted : Json.Decode.Decoder API.Events.Types.LogDeleted
decodeLogDeleted =
    Json.Decode.succeed
        (\log_id nip process_id ->
            { log_id = log_id, nip = nip, process_id = process_id }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "log_id" (Json.Decode.map LogID Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "nip" (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "process_id"
                (Json.Decode.map ProcessID Json.Decode.string)
            )


encodeLogDeleted : API.Events.Types.LogDeleted -> Json.Encode.Value
encodeLogDeleted rec =
    Json.Encode.object
        [ ( "log_id", Json.Encode.string (LogID.toValue rec.log_id) )
        , ( "nip", Json.Encode.string (NIP.toString rec.nip) )
        , ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        ]


decodeLogDeleteFailed : Json.Decode.Decoder API.Events.Types.LogDeleteFailed
decodeLogDeleteFailed =
    Json.Decode.succeed
        (\process_id reason -> { process_id = process_id, reason = reason })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "process_id" (Json.Decode.map ProcessID Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "reason" Json.Decode.string)


encodeLogDeleteFailed : API.Events.Types.LogDeleteFailed -> Json.Encode.Value
encodeLogDeleteFailed rec =
    Json.Encode.object
        [ ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        , ( "reason", Json.Encode.string rec.reason )
        ]


decodeInstallationUninstalled : Json.Decode.Decoder API.Events.Types.InstallationUninstalled
decodeInstallationUninstalled =
    Json.Decode.succeed
        (\installation_id process_id ->
            { installation_id = installation_id, process_id = process_id }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "installation_id" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "process_id"
                (Json.Decode.map ProcessID Json.Decode.string)
            )


encodeInstallationUninstalled : API.Events.Types.InstallationUninstalled -> Json.Encode.Value
encodeInstallationUninstalled rec =
    Json.Encode.object
        [ ( "installation_id", Json.Encode.string rec.installation_id )
        , ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        ]


decodeInstallationUninstallFailed : Json.Decode.Decoder API.Events.Types.InstallationUninstallFailed
decodeInstallationUninstallFailed =
    Json.Decode.succeed
        (\process_id reason -> { process_id = process_id, reason = reason })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "process_id" (Json.Decode.map ProcessID Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "reason" Json.Decode.string)


encodeInstallationUninstallFailed : API.Events.Types.InstallationUninstallFailed -> Json.Encode.Value
encodeInstallationUninstallFailed rec =
    Json.Encode.object
        [ ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        , ( "reason", Json.Encode.string rec.reason )
        ]


decodeIndexRequested : Json.Decode.Decoder API.Events.Types.IndexRequested
decodeIndexRequested =
    Json.Decode.succeed
        (\player software -> { player = player, software = software })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "player" decodeIdxPlayer)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "software"
                decodeIdxSoftware
            )


encodeIndexRequested : API.Events.Types.IndexRequested -> Json.Encode.Value
encodeIndexRequested rec =
    Json.Encode.object
        [ ( "player", encodeIdxPlayer rec.player )
        , ( "software", encodeIdxSoftware rec.software )
        ]


decodeFileTransferred : Json.Decode.Decoder API.Events.Types.FileTransferred
decodeFileTransferred =
    Json.Decode.succeed
        (\file_id process_id -> { file_id = file_id, process_id = process_id })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "file_id" (Json.Decode.map FileID Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "process_id"
                (Json.Decode.map ProcessID Json.Decode.string)
            )


encodeFileTransferred : API.Events.Types.FileTransferred -> Json.Encode.Value
encodeFileTransferred rec =
    Json.Encode.object
        [ ( "file_id", Json.Encode.string (FileID.toValue rec.file_id) )
        , ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        ]


decodeFileTransferFailed : Json.Decode.Decoder API.Events.Types.FileTransferFailed
decodeFileTransferFailed =
    Json.Decode.succeed
        (\process_id reason -> { process_id = process_id, reason = reason })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "process_id" (Json.Decode.map ProcessID Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "reason" Json.Decode.string)


encodeFileTransferFailed : API.Events.Types.FileTransferFailed -> Json.Encode.Value
encodeFileTransferFailed rec =
    Json.Encode.object
        [ ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        , ( "reason", Json.Encode.string rec.reason )
        ]


decodeFileInstalled : Json.Decode.Decoder API.Events.Types.FileInstalled
decodeFileInstalled =
    Json.Decode.succeed
        (\file_name installation_id memory_usage process_id ->
            { file_name = file_name
            , installation_id = installation_id
            , memory_usage = memory_usage
            , process_id = process_id
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "file_name" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "installation_id"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "memory_usage"
                Json.Decode.int
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "process_id"
                (Json.Decode.map ProcessID Json.Decode.string)
            )


encodeFileInstalled : API.Events.Types.FileInstalled -> Json.Encode.Value
encodeFileInstalled rec =
    Json.Encode.object
        [ ( "file_name", Json.Encode.string rec.file_name )
        , ( "installation_id", Json.Encode.string rec.installation_id )
        , ( "memory_usage", Json.Encode.int rec.memory_usage )
        , ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        ]


decodeFileInstallFailed : Json.Decode.Decoder API.Events.Types.FileInstallFailed
decodeFileInstallFailed =
    Json.Decode.succeed
        (\process_id reason -> { process_id = process_id, reason = reason })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "process_id" (Json.Decode.map ProcessID Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "reason" Json.Decode.string)


encodeFileInstallFailed : API.Events.Types.FileInstallFailed -> Json.Encode.Value
encodeFileInstallFailed rec =
    Json.Encode.object
        [ ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        , ( "reason", Json.Encode.string rec.reason )
        ]


decodeFileDeleted : Json.Decode.Decoder API.Events.Types.FileDeleted
decodeFileDeleted =
    Json.Decode.succeed
        (\file_id process_id -> { file_id = file_id, process_id = process_id })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "file_id" (Json.Decode.map FileID Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "process_id"
                (Json.Decode.map ProcessID Json.Decode.string)
            )


encodeFileDeleted : API.Events.Types.FileDeleted -> Json.Encode.Value
encodeFileDeleted rec =
    Json.Encode.object
        [ ( "file_id", Json.Encode.string (FileID.toValue rec.file_id) )
        , ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        ]


decodeFileDeleteFailed : Json.Decode.Decoder API.Events.Types.FileDeleteFailed
decodeFileDeleteFailed =
    Json.Decode.succeed
        (\process_id reason -> { process_id = process_id, reason = reason })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "process_id" (Json.Decode.map ProcessID Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "reason" Json.Decode.string)


encodeFileDeleteFailed : API.Events.Types.FileDeleteFailed -> Json.Encode.Value
encodeFileDeleteFailed rec =
    Json.Encode.object
        [ ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        , ( "reason", Json.Encode.string rec.reason )
        ]


decodeAppstoreInstalled : Json.Decode.Decoder API.Events.Types.AppstoreInstalled
decodeAppstoreInstalled =
    Json.Decode.succeed
        (\file installation nip process_id tmp_file ->
            { file = file
            , installation = installation
            , nip = nip
            , process_id = process_id
            , tmp_file = tmp_file
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "file" decodeIdxFile)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "installation"
                decodeIdxInstallation
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "nip"
                (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "process_id"
                (Json.Decode.map ProcessID Json.Decode.string)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (OpenApi.Common.decodeOptionalField
                "tmp_file"
                (Json.Decode.oneOf
                    [ Json.Decode.map
                        OpenApi.Common.Present
                        (Json.Decode.succeed
                            (\id installation_id name path size type_ version ->
                                { id =
                                    id
                                , installation_id =
                                    installation_id
                                , name =
                                    name
                                , path =
                                    path
                                , size =
                                    size
                                , type_ =
                                    type_
                                , version =
                                    version
                                }
                            )
                            |> OpenApi.Common.jsonDecodeAndMap
                                (Json.Decode.field
                                    "id"
                                    Json.Decode.string
                                )
                            |> OpenApi.Common.jsonDecodeAndMap
                                (Json.Decode.field
                                    "installation_id"
                                    (Json.Decode.oneOf
                                        [ Json.Decode.map
                                            OpenApi.Common.Present
                                            Json.Decode.string
                                        , Json.Decode.null
                                            OpenApi.Common.Null
                                        ]
                                    )
                                )
                            |> OpenApi.Common.jsonDecodeAndMap
                                (Json.Decode.field
                                    "name"
                                    Json.Decode.string
                                )
                            |> OpenApi.Common.jsonDecodeAndMap
                                (Json.Decode.field
                                    "path"
                                    Json.Decode.string
                                )
                            |> OpenApi.Common.jsonDecodeAndMap
                                (Json.Decode.field
                                    "size"
                                    Json.Decode.int
                                )
                            |> OpenApi.Common.jsonDecodeAndMap
                                (Json.Decode.field
                                    "type"
                                    Json.Decode.string
                                )
                            |> OpenApi.Common.jsonDecodeAndMap
                                (Json.Decode.field
                                    "version"
                                    Json.Decode.int
                                )
                        )
                    , Json.Decode.null
                        OpenApi.Common.Null
                    ]
                )
            )


encodeAppstoreInstalled : API.Events.Types.AppstoreInstalled -> Json.Encode.Value
encodeAppstoreInstalled rec =
    Json.Encode.object
        (List.filterMap
            Basics.identity
            [ Just ( "file", encodeIdxFile rec.file )
            , Just ( "installation", encodeIdxInstallation rec.installation )
            , Just ( "nip", Json.Encode.string (NIP.toString rec.nip) )
            , Just ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
            , Maybe.map
                (\mapUnpack ->
                    ( "tmp_file"
                    , case mapUnpack of
                        OpenApi.Common.Null ->
                            Json.Encode.null

                        OpenApi.Common.Present value ->
                            Json.Encode.object
                                [ ( "id", Json.Encode.string value.id )
                                , ( "installation_id"
                                  , case value.installation_id of
                                        OpenApi.Common.Null ->
                                            Json.Encode.null

                                        OpenApi.Common.Present value0 ->
                                            Json.Encode.string value0
                                  )
                                , ( "name", Json.Encode.string value.name )
                                , ( "path", Json.Encode.string value.path )
                                , ( "size", Json.Encode.int value.size )
                                , ( "type", Json.Encode.string value.type_ )
                                , ( "version", Json.Encode.int value.version )
                                ]
                    )
                )
                rec.tmp_file
            ]
        )


decodeAppstoreInstallFailed : Json.Decode.Decoder API.Events.Types.AppstoreInstallFailed
decodeAppstoreInstallFailed =
    Json.Decode.succeed
        (\process_id reason -> { process_id = process_id, reason = reason })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "process_id" (Json.Decode.map ProcessID Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "reason" Json.Decode.string)


encodeAppstoreInstallFailed : API.Events.Types.AppstoreInstallFailed -> Json.Encode.Value
encodeAppstoreInstallFailed rec =
    Json.Encode.object
        [ ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        , ( "reason", Json.Encode.string rec.reason )
        ]


decodeSoftwareManifest : Json.Decode.Decoder API.Events.Types.SoftwareManifest
decodeSoftwareManifest =
    Json.Decode.succeed
        (\config extension type_ ->
            { config = config, extension = extension, type_ = type_ }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "config" decodeSoftwareConfig)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "extension"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "type"
                Json.Decode.string
            )


encodeSoftwareManifest : API.Events.Types.SoftwareManifest -> Json.Encode.Value
encodeSoftwareManifest rec =
    Json.Encode.object
        [ ( "config", encodeSoftwareConfig rec.config )
        , ( "extension", Json.Encode.string rec.extension )
        , ( "type", Json.Encode.string rec.type_ )
        ]


decodeSoftwareConfigAppstore : Json.Decode.Decoder API.Events.Types.SoftwareConfigAppstore
decodeSoftwareConfigAppstore =
    Json.Decode.succeed
        (\price -> { price = price })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "price"
                Json.Decode.int
            )


encodeSoftwareConfigAppstore : API.Events.Types.SoftwareConfigAppstore -> Json.Encode.Value
encodeSoftwareConfigAppstore rec =
    Json.Encode.object [ ( "price", Json.Encode.int rec.price ) ]


decodeSoftwareConfig : Json.Decode.Decoder API.Events.Types.SoftwareConfig
decodeSoftwareConfig =
    Json.Decode.succeed
        (\appstore -> { appstore = appstore })
        |> OpenApi.Common.jsonDecodeAndMap
            (OpenApi.Common.decodeOptionalField
                "appstore"
                decodeSoftwareConfigAppstore
            )


encodeSoftwareConfig : API.Events.Types.SoftwareConfig -> Json.Encode.Value
encodeSoftwareConfig rec =
    Json.Encode.object
        (List.filterMap
            Basics.identity
            [ Maybe.map
                (\mapUnpack ->
                    ( "appstore", encodeSoftwareConfigAppstore mapUnpack )
                )
                rec.appstore
            ]
        )


decodeIdxTunnel : Json.Decode.Decoder API.Events.Types.IdxTunnel
decodeIdxTunnel =
    Json.Decode.succeed
        (\source_nip target_nip tunnel_id ->
            { source_nip = source_nip
            , target_nip = target_nip
            , tunnel_id = tunnel_id
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "source_nip" (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "target_nip"
                (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "tunnel_id"
                (Json.Decode.map TunnelID Json.Decode.string)
            )


encodeIdxTunnel : API.Events.Types.IdxTunnel -> Json.Encode.Value
encodeIdxTunnel rec =
    Json.Encode.object
        [ ( "source_nip", Json.Encode.string (NIP.toString rec.source_nip) )
        , ( "target_nip", Json.Encode.string (NIP.toString rec.target_nip) )
        , ( "tunnel_id", Json.Encode.string (TunnelID.toValue rec.tunnel_id) )
        ]


decodeIdxSoftware : Json.Decode.Decoder API.Events.Types.IdxSoftware
decodeIdxSoftware =
    Json.Decode.succeed
        (\manifest -> { manifest = manifest })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "manifest"
                (Json.Decode.list decodeSoftwareManifest)
            )


encodeIdxSoftware : API.Events.Types.IdxSoftware -> Json.Encode.Value
encodeIdxSoftware rec =
    Json.Encode.object
        [ ( "manifest", Json.Encode.list encodeSoftwareManifest rec.manifest ) ]


decodeIdxProcess : Json.Decode.Decoder API.Events.Types.IdxProcess
decodeIdxProcess =
    Json.Decode.succeed
        (\data process_id type_ ->
            { data = data, process_id = process_id, type_ = type_ }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "data" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "process_id"
                (Json.Decode.map ProcessID Json.Decode.string)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "type"
                Json.Decode.string
            )


encodeIdxProcess : API.Events.Types.IdxProcess -> Json.Encode.Value
encodeIdxProcess rec =
    Json.Encode.object
        [ ( "data", Json.Encode.string rec.data )
        , ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
        , ( "type", Json.Encode.string rec.type_ )
        ]


decodeIdxPlayer : Json.Decode.Decoder API.Events.Types.IdxPlayer
decodeIdxPlayer =
    Json.Decode.succeed
        (\endpoints gateways mainframe_id mainframe_nip ->
            { endpoints = endpoints
            , gateways = gateways
            , mainframe_id = mainframe_id
            , mainframe_nip = mainframe_nip
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "endpoints"
                (Json.Decode.list decodeIdxEndpoint)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "gateways"
                (Json.Decode.list decodeIdxGateway)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "mainframe_id"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "mainframe_nip"
                (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string)
            )


encodeIdxPlayer : API.Events.Types.IdxPlayer -> Json.Encode.Value
encodeIdxPlayer rec =
    Json.Encode.object
        [ ( "endpoints", Json.Encode.list encodeIdxEndpoint rec.endpoints )
        , ( "gateways", Json.Encode.list encodeIdxGateway rec.gateways )
        , ( "mainframe_id", Json.Encode.string rec.mainframe_id )
        , ( "mainframe_nip", Json.Encode.string (NIP.toString rec.mainframe_nip) )
        ]


decodeIdxLogRevision : Json.Decode.Decoder API.Events.Types.IdxLogRevision
decodeIdxLogRevision =
    Json.Decode.succeed
        (\data direction revision_id source type_ ->
            { data = data
            , direction = direction
            , revision_id = revision_id
            , source = source
            , type_ = type_
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "data" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "direction"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "revision_id"
                Json.Decode.int
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "source"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "type"
                Json.Decode.string
            )


encodeIdxLogRevision : API.Events.Types.IdxLogRevision -> Json.Encode.Value
encodeIdxLogRevision rec =
    Json.Encode.object
        [ ( "data", Json.Encode.string rec.data )
        , ( "direction", Json.Encode.string rec.direction )
        , ( "revision_id", Json.Encode.int rec.revision_id )
        , ( "source", Json.Encode.string rec.source )
        , ( "type", Json.Encode.string rec.type_ )
        ]


decodeIdxLog : Json.Decode.Decoder API.Events.Types.IdxLog
decodeIdxLog =
    Json.Decode.succeed
        (\id is_deleted revision_count revisions sort_strategy ->
            { id = id
            , is_deleted = is_deleted
            , revision_count = revision_count
            , revisions = revisions
            , sort_strategy = sort_strategy
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "id" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "is_deleted"
                Json.Decode.bool
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "revision_count"
                Json.Decode.int
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "revisions"
                (Json.Decode.list
                    decodeIdxLogRevision
                )
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "sort_strategy"
                Json.Decode.string
            )


encodeIdxLog : API.Events.Types.IdxLog -> Json.Encode.Value
encodeIdxLog rec =
    Json.Encode.object
        [ ( "id", Json.Encode.string rec.id )
        , ( "is_deleted", Json.Encode.bool rec.is_deleted )
        , ( "revision_count", Json.Encode.int rec.revision_count )
        , ( "revisions", Json.Encode.list encodeIdxLogRevision rec.revisions )
        , ( "sort_strategy", Json.Encode.string rec.sort_strategy )
        ]


decodeIdxInstallation : Json.Decode.Decoder API.Events.Types.IdxInstallation
decodeIdxInstallation =
    Json.Decode.succeed
        (\file_id file_type file_version id memory_usage ->
            { file_id = file_id
            , file_type = file_type
            , file_version = file_version
            , id = id
            , memory_usage = memory_usage
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "file_id"
                (Json.Decode.oneOf
                    [ Json.Decode.map
                        OpenApi.Common.Present
                        Json.Decode.string
                    , Json.Decode.null OpenApi.Common.Null
                    ]
                )
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "file_type"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "file_version"
                Json.Decode.int
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "id"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "memory_usage"
                Json.Decode.int
            )


encodeIdxInstallation : API.Events.Types.IdxInstallation -> Json.Encode.Value
encodeIdxInstallation rec =
    Json.Encode.object
        [ ( "file_id"
          , case rec.file_id of
                OpenApi.Common.Null ->
                    Json.Encode.null

                OpenApi.Common.Present value ->
                    Json.Encode.string value
          )
        , ( "file_type", Json.Encode.string rec.file_type )
        , ( "file_version", Json.Encode.int rec.file_version )
        , ( "id", Json.Encode.string rec.id )
        , ( "memory_usage", Json.Encode.int rec.memory_usage )
        ]


decodeIdxGateway : Json.Decode.Decoder API.Events.Types.IdxGateway
decodeIdxGateway =
    Json.Decode.succeed
        (\files id installations logs nip processes tunnels ->
            { files = files
            , id = id
            , installations = installations
            , logs = logs
            , nip = nip
            , processes = processes
            , tunnels = tunnels
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "files" (Json.Decode.list decodeIdxFile))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "id" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "installations"
                (Json.Decode.list
                    decodeIdxInstallation
                )
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "logs"
                (Json.Decode.list
                    decodeIdxLog
                )
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "nip"
                (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "processes"
                (Json.Decode.list
                    decodeIdxProcess
                )
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "tunnels"
                (Json.Decode.list
                    decodeIdxTunnel
                )
            )


encodeIdxGateway : API.Events.Types.IdxGateway -> Json.Encode.Value
encodeIdxGateway rec =
    Json.Encode.object
        [ ( "files", Json.Encode.list encodeIdxFile rec.files )
        , ( "id", Json.Encode.string rec.id )
        , ( "installations"
          , Json.Encode.list encodeIdxInstallation rec.installations
          )
        , ( "logs", Json.Encode.list encodeIdxLog rec.logs )
        , ( "nip", Json.Encode.string (NIP.toString rec.nip) )
        , ( "processes", Json.Encode.list encodeIdxProcess rec.processes )
        , ( "tunnels", Json.Encode.list encodeIdxTunnel rec.tunnels )
        ]


decodeIdxFile : Json.Decode.Decoder API.Events.Types.IdxFile
decodeIdxFile =
    Json.Decode.succeed
        (\id installation_id name path size type_ version ->
            { id = id
            , installation_id = installation_id
            , name = name
            , path = path
            , size = size
            , type_ = type_
            , version = version
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "id" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "installation_id"
                (Json.Decode.oneOf
                    [ Json.Decode.map
                        OpenApi.Common.Present
                        Json.Decode.string
                    , Json.Decode.null
                        OpenApi.Common.Null
                    ]
                )
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "name"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "path"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "size"
                Json.Decode.int
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "type"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "version"
                Json.Decode.int
            )


encodeIdxFile : API.Events.Types.IdxFile -> Json.Encode.Value
encodeIdxFile rec =
    Json.Encode.object
        [ ( "id", Json.Encode.string rec.id )
        , ( "installation_id"
          , case rec.installation_id of
                OpenApi.Common.Null ->
                    Json.Encode.null

                OpenApi.Common.Present value ->
                    Json.Encode.string value
          )
        , ( "name", Json.Encode.string rec.name )
        , ( "path", Json.Encode.string rec.path )
        , ( "size", Json.Encode.int rec.size )
        , ( "type", Json.Encode.string rec.type_ )
        , ( "version", Json.Encode.int rec.version )
        ]


decodeIdxEndpoint : Json.Decode.Decoder API.Events.Types.IdxEndpoint
decodeIdxEndpoint =
    Json.Decode.succeed
        (\files logs nip processes ->
            { files = files, logs = logs, nip = nip, processes = processes }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "files" (Json.Decode.list decodeIdxFile))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "logs"
                (Json.Decode.list decodeIdxLog)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "nip"
                (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string)
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "processes"
                (Json.Decode.list
                    decodeIdxProcess
                )
            )


encodeIdxEndpoint : API.Events.Types.IdxEndpoint -> Json.Encode.Value
encodeIdxEndpoint rec =
    Json.Encode.object
        [ ( "files", Json.Encode.list encodeIdxFile rec.files )
        , ( "logs", Json.Encode.list encodeIdxLog rec.logs )
        , ( "nip", Json.Encode.string (NIP.toString rec.nip) )
        , ( "processes", Json.Encode.list encodeIdxProcess rec.processes )
        ]
