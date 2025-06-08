-- This is an auto-generated file; manual changes will be overwritten!


module API.Events.Json exposing
    ( encodeFileDeleteFailed, encodeFileDeleted, encodeFileInstallFailed, encodeFileInstalled
    , encodeFileTransferFailed, encodeFileTransferred, encodeIdxEndpoint, encodeIdxGateway, encodeIdxLog
    , encodeIdxPlayer, encodeIdxProcess, encodeIdxTunnel, encodeIndexRequested
    , encodeInstallationUninstallFailed, encodeInstallationUninstalled, encodeLogDeleteFailed, encodeLogDeleted
    , encodeLogEditFailed, encodeLogEdited, encodeProcessCompleted, encodeProcessCreated, encodeProcessKilled
    , encodeTunnelCreated
    , decodeFileDeleteFailed, decodeFileDeleted, decodeFileInstallFailed, decodeFileInstalled
    , decodeFileTransferFailed, decodeFileTransferred, decodeIdxEndpoint, decodeIdxGateway, decodeIdxLog
    , decodeIdxPlayer, decodeIdxProcess, decodeIdxTunnel, decodeIndexRequested
    , decodeInstallationUninstallFailed, decodeInstallationUninstalled, decodeLogDeleteFailed, decodeLogDeleted
    , decodeLogEditFailed, decodeLogEdited, decodeProcessCompleted, decodeProcessCreated, decodeProcessKilled
    , decodeTunnelCreated
    )

{-|


## Encoders

@docs encodeFileDeleteFailed, encodeFileDeleted, encodeFileInstallFailed, encodeFileInstalled
@docs encodeFileTransferFailed, encodeFileTransferred, encodeIdxEndpoint, encodeIdxGateway, encodeIdxLog
@docs encodeIdxPlayer, encodeIdxProcess, encodeIdxTunnel, encodeIndexRequested
@docs encodeInstallationUninstallFailed, encodeInstallationUninstalled, encodeLogDeleteFailed, encodeLogDeleted
@docs encodeLogEditFailed, encodeLogEdited, encodeProcessCompleted, encodeProcessCreated, encodeProcessKilled
@docs encodeTunnelCreated


## Decoders

@docs decodeFileDeleteFailed, decodeFileDeleted, decodeFileInstallFailed, decodeFileInstalled
@docs decodeFileTransferFailed, decodeFileTransferred, decodeIdxEndpoint, decodeIdxGateway, decodeIdxLog
@docs decodeIdxPlayer, decodeIdxProcess, decodeIdxTunnel, decodeIndexRequested
@docs decodeInstallationUninstallFailed, decodeInstallationUninstalled, decodeLogDeleteFailed, decodeLogDeleted
@docs decodeLogEditFailed, decodeLogEdited, decodeProcessCompleted, decodeProcessCreated, decodeProcessKilled
@docs decodeTunnelCreated

-}

import API.Events.Types
import Game.Model.LogID as LogID exposing (LogID(..))
import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ProcessID as ProcessID exposing (ProcessID(..))
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


encodeLogEdited : API.Events.Types.LogEdited -> Json.Encode.Value
encodeLogEdited rec =
    Json.Encode.object
        [ ( "log_id", Json.Encode.string (LogID.toValue rec.log_id) )
        , ( "nip", Json.Encode.string (NIP.toString rec.nip) )
        , ( "process_id", Json.Encode.string (ProcessID.toValue rec.process_id) )
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
        (\player -> { player = player })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "player"
                decodeIdxPlayer
            )


encodeIndexRequested : API.Events.Types.IndexRequested -> Json.Encode.Value
encodeIndexRequested rec =
    Json.Encode.object [ ( "player", encodeIdxPlayer rec.player ) ]


decodeFileTransferred : Json.Decode.Decoder API.Events.Types.FileTransferred
decodeFileTransferred =
    Json.Decode.succeed
        (\file_id process_id -> { file_id = file_id, process_id = process_id })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "file_id" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "process_id"
                (Json.Decode.map ProcessID Json.Decode.string)
            )


encodeFileTransferred : API.Events.Types.FileTransferred -> Json.Encode.Value
encodeFileTransferred rec =
    Json.Encode.object
        [ ( "file_id", Json.Encode.string rec.file_id )
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
            (Json.Decode.field "file_id" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "process_id"
                (Json.Decode.map ProcessID Json.Decode.string)
            )


encodeFileDeleted : API.Events.Types.FileDeleted -> Json.Encode.Value
encodeFileDeleted rec =
    Json.Encode.object
        [ ( "file_id", Json.Encode.string rec.file_id )
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
        (\endpoints gateways mainframe_nip ->
            { endpoints = endpoints
            , gateways = gateways
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
                "mainframe_nip"
                (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string)
            )


encodeIdxPlayer : API.Events.Types.IdxPlayer -> Json.Encode.Value
encodeIdxPlayer rec =
    Json.Encode.object
        [ ( "endpoints", Json.Encode.list encodeIdxEndpoint rec.endpoints )
        , ( "gateways", Json.Encode.list encodeIdxGateway rec.gateways )
        , ( "mainframe_nip", Json.Encode.string (NIP.toString rec.mainframe_nip) )
        ]


decodeIdxLog : Json.Decode.Decoder API.Events.Types.IdxLog
decodeIdxLog =
    Json.Decode.succeed
        (\data direction id is_deleted revision_id type_ ->
            { data = data
            , direction = direction
            , id = id
            , is_deleted = is_deleted
            , revision_id = revision_id
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
                "id"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "is_deleted"
                Json.Decode.bool
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "revision_id"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "type"
                Json.Decode.string
            )


encodeIdxLog : API.Events.Types.IdxLog -> Json.Encode.Value
encodeIdxLog rec =
    Json.Encode.object
        [ ( "data", Json.Encode.string rec.data )
        , ( "direction", Json.Encode.string rec.direction )
        , ( "id", Json.Encode.string rec.id )
        , ( "is_deleted", Json.Encode.bool rec.is_deleted )
        , ( "revision_id", Json.Encode.string rec.revision_id )
        , ( "type", Json.Encode.string rec.type_ )
        ]


decodeIdxGateway : Json.Decode.Decoder API.Events.Types.IdxGateway
decodeIdxGateway =
    Json.Decode.succeed
        (\logs nip processes tunnels ->
            { logs = logs
            , nip = nip
            , processes = processes
            , tunnels = tunnels
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "logs" (Json.Decode.list decodeIdxLog))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "nip" (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string))
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
        [ ( "logs", Json.Encode.list encodeIdxLog rec.logs )
        , ( "nip", Json.Encode.string (NIP.toString rec.nip) )
        , ( "processes", Json.Encode.list encodeIdxProcess rec.processes )
        , ( "tunnels", Json.Encode.list encodeIdxTunnel rec.tunnels )
        ]


decodeIdxEndpoint : Json.Decode.Decoder API.Events.Types.IdxEndpoint
decodeIdxEndpoint =
    Json.Decode.succeed
        (\logs nip processes ->
            { logs = logs, nip = nip, processes = processes }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "logs" (Json.Decode.list decodeIdxLog))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "nip" (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string))
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
        [ ( "logs", Json.Encode.list encodeIdxLog rec.logs )
        , ( "nip", Json.Encode.string (NIP.toString rec.nip) )
        , ( "processes", Json.Encode.list encodeIdxProcess rec.processes )
        ]
