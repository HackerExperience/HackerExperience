-- This is an auto-generated file; manual changes will be overwritten!


module API.Processes.Types exposing (FileDelete, FileInstall, FileTransfer, InstallationUninstall, LogDelete, LogEdit)

import Game.Model.LogID as LogID exposing (LogID(..))
import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ProcessID as ProcessID exposing (ProcessID(..))
import Game.Model.TunnelID as TunnelID exposing (TunnelID(..))


{-|


## Aliases

@docs FileDelete, FileInstall, FileTransfer, InstallationUninstall, LogDelete, LogEdit

-}
type alias LogEdit =
    { log_id : LogID }


type alias LogDelete =
    { log_id : LogID }


type alias InstallationUninstall =
    {}


type alias FileTransfer =
    {}


type alias FileInstall =
    {}


type alias FileDelete =
    {}
