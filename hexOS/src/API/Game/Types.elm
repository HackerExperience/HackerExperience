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
    , InstallationUninstallInput
    , InstallationUninstallOkResponse
    , InstallationUninstallOutput
    , InstallationUninstallRequest
    , PlayerSyncInput
    , PlayerSyncOkResponse
    , PlayerSyncOutput
    , PlayerSyncRequest
    , ServerLoginInput
    , ServerLoginOkResponse
    , ServerLoginOutput
    , ServerLoginRequest
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

-}
type alias ServerLoginOutput =
    {}


type alias ServerLoginInput =
    { tunnel_id : Maybe TunnelID }


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
