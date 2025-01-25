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
    , ProcessCreated
    , ProcessKilled
    , TunnelCreated
    )

import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ServerID as ServerID exposing (ServerID(..))
import Game.Model.TunnelID as TunnelID exposing (TunnelID(..))


{-|


## Aliases

@docs FileDeleteFailed, FileDeleted, FileInstallFailed, FileInstalled, FileTransferFailed, FileTransferred
@docs IdxEndpoint, IdxGateway, IdxLog, IdxPlayer, IdxTunnel, IndexRequested, InstallationUninstallFailed
@docs InstallationUninstalled, ProcessCompleted, ProcessCreated, ProcessKilled, TunnelCreated

-}
type alias TunnelCreated =
    { access : String
    , index : IdxEndpoint
    , source_nip : NIP
    , target_nip : NIP
    , tunnel_id : TunnelID
    }


type alias ProcessKilled =
    { process_id : Int, reason : String }


type alias ProcessCreated =
    { id : Int, type_ : String }


type alias ProcessCompleted =
    { process_id : Int }


type alias InstallationUninstalled =
    { installation_id : Int, process_id : Int }


type alias InstallationUninstallFailed =
    { process_id : Int, reason : String }


type alias IndexRequested =
    { player : IdxPlayer }


type alias FileTransferred =
    { file_id : Int, process_id : Int }


type alias FileTransferFailed =
    { process_id : Int, reason : String }


type alias FileInstalled =
    { file_name : String
    , installation_id : Int
    , memory_usage : Int
    , process_id : Int
    }


type alias FileInstallFailed =
    { process_id : Int, reason : String }


type alias FileDeleted =
    { file_id : Int, process_id : Int }


type alias FileDeleteFailed =
    { process_id : Int, reason : String }


type alias IdxTunnel =
    { source_nip : NIP, target_nip : NIP, tunnel_id : TunnelID }


type alias IdxPlayer =
    { endpoints : List IdxEndpoint
    , gateways : List IdxGateway
    , mainframe_id : ServerID
    }


type alias IdxLog =
    { id : Int, revision_id : Int, type_ : String }


type alias IdxGateway =
    { id : Int, logs : List IdxLog, nip : NIP, tunnels : List IdxTunnel }


type alias IdxEndpoint =
    { logs : List IdxLog, nip : NIP }
