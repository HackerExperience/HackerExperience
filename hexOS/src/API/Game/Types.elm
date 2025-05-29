-- This is an auto-generated file; manual changes will be overwritten!


module API.Game.Types exposing
    ( FileDeleteInput
    , FileDeleteOkResponse
    , FileDeleteOutput
    , FileDeleteRequest
    , FileInstallInput
    , FileInstallOkResponse
    , FileInstallOutput
    , FileInstallRequest
    , FileTransferInput
    , FileTransferOkResponse
    , FileTransferOutput
    , FileTransferRequest
    , GenericBadRequest
    , GenericBadRequestResponse
    , GenericError
    , GenericErrorResponse
    , GenericUnauthorizedResponse
    , IdxProcess
    , InstallationUninstallInput
    , InstallationUninstallOkResponse
    , InstallationUninstallOutput
    , InstallationUninstallRequest
    , LogDeleteInput
    , LogDeleteOkResponse
    , LogDeleteOutput
    , LogDeleteRequest
    , LogEditInput
    , LogEditOkResponse
    , LogEditOutput
    , LogEditRequest
    , PlayerSyncInput
    , PlayerSyncOkResponse
    , PlayerSyncOutput
    , PlayerSyncRequest
    , ServerLoginInput
    , ServerLoginOkResponse
    , ServerLoginOutput
    , ServerLoginRequest
    )

import Game.Model.LogID as LogID exposing (LogID(..))
import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ProcessID as ProcessID exposing (ProcessID(..))
import Game.Model.TunnelID as TunnelID exposing (TunnelID(..))


{-|


## Aliases

@docs FileDeleteInput, FileDeleteOkResponse, FileDeleteOutput, FileDeleteRequest, FileInstallInput
@docs FileInstallOkResponse, FileInstallOutput, FileInstallRequest, FileTransferInput, FileTransferOkResponse
@docs FileTransferOutput, FileTransferRequest, GenericBadRequest, GenericBadRequestResponse, GenericError
@docs GenericErrorResponse, GenericUnauthorizedResponse, IdxProcess, InstallationUninstallInput
@docs InstallationUninstallOkResponse, InstallationUninstallOutput, InstallationUninstallRequest, LogDeleteInput
@docs LogDeleteOkResponse, LogDeleteOutput, LogDeleteRequest, LogEditInput, LogEditOkResponse, LogEditOutput
@docs LogEditRequest, PlayerSyncInput, PlayerSyncOkResponse, PlayerSyncOutput, PlayerSyncRequest
@docs ServerLoginInput, ServerLoginOkResponse, ServerLoginOutput, ServerLoginRequest

-}
type alias ServerLoginOutput =
    {}


type alias ServerLoginInput =
    { tunnel_id : Maybe TunnelID }


type alias PlayerSyncOutput =
    {}


type alias PlayerSyncInput =
    { token : Maybe String }


type alias LogEditOutput =
    {}


type alias LogEditInput =
    { tunnel_id : Maybe TunnelID }


type alias LogDeleteOutput =
    { log_id : LogID, process : IdxProcess }


type alias LogDeleteInput =
    { tunnel_id : Maybe TunnelID }


type alias InstallationUninstallOutput =
    {}


type alias InstallationUninstallInput =
    {}


type alias IdxProcess =
    { data : String, process_id : ProcessID, type_ : String }


type alias GenericError =
    { details : Maybe String, msg : String }


type alias GenericBadRequest =
    { details : Maybe String, msg : String }


type alias FileTransferOutput =
    {}


type alias FileTransferInput =
    { transfer_type : String, tunnel_id : TunnelID }


type alias FileInstallOutput =
    {}


type alias FileInstallInput =
    {}


type alias FileDeleteOutput =
    {}


type alias FileDeleteInput =
    { tunnel_id : Maybe TunnelID }


type alias ServerLoginOkResponse =
    { data : ServerLoginOutput }


type alias PlayerSyncOkResponse =
    { data : PlayerSyncOutput }


type alias LogEditOkResponse =
    { data : LogEditOutput }


type alias LogDeleteOkResponse =
    { data : LogDeleteOutput }


type alias InstallationUninstallOkResponse =
    { data : InstallationUninstallOutput }


type alias GenericUnauthorizedResponse =
    ()


type alias GenericErrorResponse =
    { error : GenericError }


type alias GenericBadRequestResponse =
    { error : GenericBadRequest }


type alias FileTransferOkResponse =
    { data : FileTransferOutput }


type alias FileInstallOkResponse =
    { data : FileInstallOutput }


type alias FileDeleteOkResponse =
    { data : FileDeleteOutput }


type alias ServerLoginRequest =
    ServerLoginInput


type alias PlayerSyncRequest =
    PlayerSyncInput


type alias LogEditRequest =
    LogEditInput


type alias LogDeleteRequest =
    LogDeleteInput


type alias InstallationUninstallRequest =
    InstallationUninstallInput


type alias FileTransferRequest =
    FileTransferInput


type alias FileInstallRequest =
    FileInstallInput


type alias FileDeleteRequest =
    FileDeleteInput
