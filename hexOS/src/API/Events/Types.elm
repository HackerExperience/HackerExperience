-- This is an auto-generated file; manual changes will be overwritten!


module API.Events.Types exposing
    ( FileDeleteFailed
    , FileDeleted
    , FileInstallFailed
    , FileInstalled
    , FileTransferFailed
    , FileTransferred
    , IdxEndpoint
    , IdxGateway
    , IdxLog
    , IdxPlayer
    , IdxProcess
    , IdxTunnel
    , IndexRequested
    , InstallationUninstallFailed
    , InstallationUninstalled
    , LogDeleteFailed
    , LogDeleted
    , ProcessCompleted
    , ProcessKilled
    , TunnelCreated
    )

import Game.Model.LogID as LogID exposing (LogID(..))
import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ProcessID as ProcessID exposing (ProcessID(..))
import Game.Model.TunnelID as TunnelID exposing (TunnelID(..))


{-|


## Aliases

@docs FileDeleteFailed, FileDeleted, FileInstallFailed, FileInstalled, FileTransferFailed, FileTransferred
@docs IdxEndpoint, IdxGateway, IdxLog, IdxPlayer, IdxProcess, IdxTunnel, IndexRequested
@docs InstallationUninstallFailed, InstallationUninstalled, LogDeleteFailed, LogDeleted, ProcessCompleted
@docs ProcessKilled, TunnelCreated

-}
type alias TunnelCreated =
    { access : String
    , index : IdxEndpoint
    , source_nip : NIP
    , target_nip : NIP
    , tunnel_id : TunnelID
    }


type alias ProcessKilled =
    { process_id : ProcessID, reason : String }


type alias ProcessCompleted =
    { data : String, nip : NIP, process_id : ProcessID, type_ : String }


type alias LogDeleted =
    { log_id : LogID, nip : NIP, process_id : ProcessID }


type alias LogDeleteFailed =
    { process_id : ProcessID, reason : String }


type alias InstallationUninstalled =
    { installation_id : String, process_id : ProcessID }


type alias InstallationUninstallFailed =
    { process_id : ProcessID, reason : String }


type alias IndexRequested =
    { player : IdxPlayer }


type alias FileTransferred =
    { file_id : String, process_id : ProcessID }


type alias FileTransferFailed =
    { process_id : ProcessID, reason : String }


type alias FileInstalled =
    { file_name : String
    , installation_id : String
    , memory_usage : Int
    , process_id : ProcessID
    }


type alias FileInstallFailed =
    { process_id : ProcessID, reason : String }


type alias FileDeleted =
    { file_id : String, process_id : ProcessID }


type alias FileDeleteFailed =
    { process_id : ProcessID, reason : String }


type alias IdxTunnel =
    { source_nip : NIP, target_nip : NIP, tunnel_id : TunnelID }


type alias IdxProcess =
    { data : String, process_id : ProcessID, type_ : String }


type alias IdxPlayer =
    { endpoints : List IdxEndpoint
    , gateways : List IdxGateway
    , mainframe_nip : NIP
    }


type alias IdxLog =
    { id : String, is_deleted : Bool, revision_id : String, type_ : String }


type alias IdxGateway =
    { logs : List IdxLog
    , nip : NIP
    , processes : List IdxProcess
    , tunnels : List IdxTunnel
    }


type alias IdxEndpoint =
    { logs : List IdxLog, nip : NIP, processes : List IdxProcess }
