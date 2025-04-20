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
    , IdxTunnel
    , IndexRequested
    , InstallationUninstallFailed
    , InstallationUninstalled
    , ProcessCompleted
    , ProcessKilled
    , TunnelCreated
    )

import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.TunnelID as TunnelID exposing (TunnelID(..))


{-|


## Aliases

@docs FileDeleteFailed, FileDeleted, FileInstallFailed, FileInstalled, FileTransferFailed, FileTransferred
@docs IdxEndpoint, IdxGateway, IdxLog, IdxPlayer, IdxTunnel, IndexRequested, InstallationUninstallFailed
@docs InstallationUninstalled, ProcessCompleted, ProcessKilled, TunnelCreated

-}
type alias TunnelCreated =
    { access : String
    , index : IdxEndpoint
    , source_nip : NIP
    , target_nip : NIP
    , tunnel_id : TunnelID
    }


type alias ProcessKilled =
    { process_id : String, reason : String }


type alias ProcessCompleted =
    { process_id : String }


type alias InstallationUninstalled =
    { installation_id : String, process_id : String }


type alias InstallationUninstallFailed =
    { process_id : String, reason : String }


type alias IndexRequested =
    { player : IdxPlayer }


type alias FileTransferred =
    { file_id : String, process_id : String }


type alias FileTransferFailed =
    { process_id : String, reason : String }


type alias FileInstalled =
    { file_name : String
    , installation_id : String
    , memory_usage : Int
    , process_id : String
    }


type alias FileInstallFailed =
    { process_id : String, reason : String }


type alias FileDeleted =
    { file_id : String, process_id : String }


type alias FileDeleteFailed =
    { process_id : String, reason : String }


type alias IdxTunnel =
    { source_nip : NIP, target_nip : NIP, tunnel_id : TunnelID }


type alias IdxPlayer =
    { endpoints : List IdxEndpoint
    , gateways : List IdxGateway
    , mainframe_nip : NIP
    }


type alias IdxLog =
    { id : String, is_deleted : Bool, revision_id : String, type_ : String }


type alias IdxGateway =
    { logs : List IdxLog, nip : NIP, tunnels : List IdxTunnel }


type alias IdxEndpoint =
    { logs : List IdxLog, nip : NIP }
