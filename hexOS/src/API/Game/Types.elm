-- This is an auto-generated file; manual changes will be overwritten!


module API.Game.Types exposing
    ( FileDeleteInput
    , FileDeleteOkResponse
    , FileDeleteOutput
    , FileDeleteRequest
    , FileDelete_Error
    , FileInstallInput
    , FileInstallOkResponse
    , FileInstallOutput
    , FileInstallRequest
    , FileInstall_Error
    , FileTransferInput
    , FileTransferOkResponse
    , FileTransferOutput
    , FileTransferRequest
    , FileTransfer_Error
    , GenericBadRequest
    , GenericBadRequestResponse
    , GenericError
    , GenericErrorResponse
    , GenericUnauthorizedResponse
    , InstallationUninstallInput
    , InstallationUninstallOkResponse
    , InstallationUninstallOutput
    , InstallationUninstallRequest
    , InstallationUninstall_Error
    , PlayerSyncInput
    , PlayerSyncOkResponse
    , PlayerSyncOutput
    , PlayerSyncRequest
    , PlayerSync_Error(..)
    , ServerLoginInput
    , ServerLoginOkResponse
    , ServerLoginOutput
    , ServerLoginRequest
    , ServerLogin_Error
    )

import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ServerID as ServerID exposing (ServerID(..))
import Game.Model.TunnelID as TunnelID exposing (TunnelID(..))


{-|


## Aliases

@docs FileDeleteInput, FileDeleteOkResponse, FileDeleteOutput, FileDeleteRequest, FileInstallInput
@docs FileInstallOkResponse, FileInstallOutput, FileInstallRequest, FileTransferInput, FileTransferOkResponse
@docs FileTransferOutput, FileTransferRequest, GenericBadRequest, GenericBadRequestResponse, GenericError
@docs GenericErrorResponse, GenericUnauthorizedResponse, InstallationUninstallInput
@docs InstallationUninstallOkResponse, InstallationUninstallOutput, InstallationUninstallRequest
@docs PlayerSyncInput, PlayerSyncOkResponse, PlayerSyncOutput, PlayerSyncRequest, ServerLoginInput
@docs ServerLoginOkResponse, ServerLoginOutput, ServerLoginRequest


## Errors

@docs FileDelete_Error, FileInstall_Error, FileTransfer_Error, InstallationUninstall_Error, PlayerSync_Error
@docs ServerLogin_Error

-}
type PlayerSync_Error
    = PlayerSync_400 GenericBadRequestResponse


type alias FileDelete_Error =
    Never


type alias FileInstall_Error =
    Never


type alias FileTransfer_Error =
    Never


type alias InstallationUninstall_Error =
    Never


type alias ServerLogin_Error =
    Never


type alias ServerLoginOutput =
    {}


type alias ServerLoginInput =
    { tunnel_id : Maybe String }


type alias PlayerSyncOutput =
    {}


type alias PlayerSyncInput =
    { token : Maybe String }


type alias InstallationUninstallOutput =
    {}


type alias InstallationUninstallInput =
    {}


type alias GenericError =
    { details : Maybe String, msg : String }


type alias GenericBadRequest =
    { details : Maybe String, msg : String }


type alias FileTransferOutput =
    {}


type alias FileTransferInput =
    { transfer_type : String, tunnel_id : String }


type alias FileInstallOutput =
    {}


type alias FileInstallInput =
    {}


type alias FileDeleteOutput =
    {}


type alias FileDeleteInput =
    { tunnel_id : Maybe String }


type alias ServerLoginOkResponse =
    { data : ServerLoginOutput }


type alias PlayerSyncOkResponse =
    { data : PlayerSyncOutput }


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


type alias InstallationUninstallRequest =
    InstallationUninstallInput


type alias FileTransferRequest =
    FileTransferInput


type alias FileInstallRequest =
    FileInstallInput


type alias FileDeleteRequest =
    FileDeleteInput
