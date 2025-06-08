-- This is an auto-generated file; manual changes will be overwritten!


module API.Logs.Types exposing (LogDataEmpty, LogDataLocalFile, LogDataNIP, LogDataNIPProxy, LogDataRemoteFile)

import Game.Model.LogID as LogID exposing (LogID(..))
import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ProcessID as ProcessID exposing (ProcessID(..))
import Game.Model.TunnelID as TunnelID exposing (TunnelID(..))


{-|


## Aliases

@docs LogDataEmpty, LogDataLocalFile, LogDataNIP, LogDataNIPProxy, LogDataRemoteFile

-}
type alias LogDataRemoteFile =
    { file_ext : String, file_name : String, file_version : Int, nip : NIP }


type alias LogDataNIPProxy =
    { from_nip : NIP, to_nip : NIP }


type alias LogDataNIP =
    { nip : NIP }


type alias LogDataLocalFile =
    { file_ext : String, file_name : String, file_version : Int }


type alias LogDataEmpty =
    {}
