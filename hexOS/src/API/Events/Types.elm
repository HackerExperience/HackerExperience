-- This is an auto-generated file; manual changes will be overwritten!


module API.Events.Types exposing
    ( AppstoreInstallFailed, AppstoreInstalled, FileDeleteFailed, FileDeleted, FileInstallFailed, FileInstalled
    , FileTransferFailed, FileTransferred, IdxEndpoint, IdxFile, IdxGateway, IdxInstallation, IdxLog
    , IdxLogRevision, IdxPlayer, IdxProcess, IdxSoftware, IdxTunnel, IndexRequested, InstallationUninstallFailed
    , InstallationUninstalled, LogDeleteFailed, LogDeleted, LogEditFailed, LogEdited, ProcessCompleted
    , ProcessCreated, ProcessKilled, SoftwareConfig, SoftwareConfigAppstore, SoftwareManifest, TunnelCreated
    )

{-|


## Aliases

@docs AppstoreInstallFailed, AppstoreInstalled, FileDeleteFailed, FileDeleted, FileInstallFailed, FileInstalled
@docs FileTransferFailed, FileTransferred, IdxEndpoint, IdxFile, IdxGateway, IdxInstallation, IdxLog
@docs IdxLogRevision, IdxPlayer, IdxProcess, IdxSoftware, IdxTunnel, IndexRequested, InstallationUninstallFailed
@docs InstallationUninstalled, LogDeleteFailed, LogDeleted, LogEditFailed, LogEdited, ProcessCompleted
@docs ProcessCreated, ProcessKilled, SoftwareConfig, SoftwareConfigAppstore, SoftwareManifest, TunnelCreated

-}

import Game.Model.FileID as FileID exposing (FileID(..))
import Game.Model.LogID as LogID exposing (LogID(..))
import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ProcessID as ProcessID exposing (ProcessID(..))
import Game.Model.ServerID as ServerID exposing (ServerID(..))
import Game.Model.TunnelID as TunnelID exposing (TunnelID(..))
import OpenApi.Common


type alias TunnelCreated =
    { access : String
    , index : IdxEndpoint
    , source_nip : NIP
    , target_nip : NIP
    , tunnel_id : TunnelID
    }


type alias ProcessKilled =
    { process_id : ProcessID, reason : String }


type alias ProcessCreated =
    { data : String, nip : NIP, process_id : ProcessID, type_ : String }


type alias ProcessCompleted =
    { data : String, nip : NIP, process_id : ProcessID, type_ : String }


type alias LogEdited =
    { data : String
    , direction : String
    , log_id : LogID
    , nip : NIP
    , process_id : ProcessID
    , type_ : String
    }


type alias LogEditFailed =
    { process_id : ProcessID, reason : String }


type alias LogDeleted =
    { log_id : LogID, nip : NIP, process_id : ProcessID }


type alias LogDeleteFailed =
    { process_id : ProcessID, reason : String }


type alias InstallationUninstalled =
    { installation_id : String, process_id : ProcessID }


type alias InstallationUninstallFailed =
    { process_id : ProcessID, reason : String }


type alias IndexRequested =
    { player : IdxPlayer, software : IdxSoftware }


type alias FileTransferred =
    { file_id : FileID, process_id : ProcessID }


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
    { file_id : FileID, process_id : ProcessID }


type alias FileDeleteFailed =
    { process_id : ProcessID, reason : String }


type alias AppstoreInstalled =
    { file :
        OpenApi.Common.Nullable
            { id : String
            , name : String
            , path : String
            , size : Int
            , type_ : String
            , version : Int
            }
    , installation :
        OpenApi.Common.Nullable
            { file_id : OpenApi.Common.Nullable String
            , file_type : String
            , file_version : Int
            , id : String
            , memory_usage : Int
            }
    , nip : NIP
    , process_id : ProcessID
    }


type alias AppstoreInstallFailed =
    { process_id : ProcessID, reason : String }


type alias SoftwareManifest =
    { config : SoftwareConfig, extension : String, type_ : String }


type alias SoftwareConfigAppstore =
    { price : Int }


type alias SoftwareConfig =
    { appstore : Maybe SoftwareConfigAppstore }


type alias IdxTunnel =
    { source_nip : NIP, target_nip : NIP, tunnel_id : TunnelID }


type alias IdxSoftware =
    { manifest : List SoftwareManifest }


type alias IdxProcess =
    { data : String, process_id : ProcessID, type_ : String }


type alias IdxPlayer =
    { endpoints : List IdxEndpoint
    , gateways : List IdxGateway
    , mainframe_id : String
    , mainframe_nip : NIP
    }


type alias IdxLogRevision =
    { data : String
    , direction : String
    , revision_id : Int
    , source : String
    , type_ : String
    }


type alias IdxLog =
    { id : String
    , is_deleted : Bool
    , revision_count : Int
    , revisions : List IdxLogRevision
    , sort_strategy : String
    }


type alias IdxInstallation =
    { file_id : OpenApi.Common.Nullable String
    , file_type : String
    , file_version : Int
    , id : String
    , memory_usage : Int
    }


type alias IdxGateway =
    { files : List IdxFile
    , id : String
    , installations : List IdxInstallation
    , logs : List IdxLog
    , nip : NIP
    , processes : List IdxProcess
    , tunnels : List IdxTunnel
    }


type alias IdxFile =
    { id : String
    , name : String
    , path : String
    , size : Int
    , type_ : String
    , version : Int
    }


type alias IdxEndpoint =
    { files : List IdxFile
    , logs : List IdxLog
    , nip : NIP
    , processes : List IdxProcess
    }
