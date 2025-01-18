-- This is an auto-generated file; manual changes will be overwritten!


module API.Game.Types exposing
    ( FileInstallInput
    , FileInstallOkResponse
    , FileInstallOutput
    , FileInstallRequest
    , FileInstall_Error
    , GenericBadRequest
    , GenericBadRequestResponse
    , GenericError
    , GenericErrorResponse
    , GenericUnauthorizedResponse
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

@docs FileInstallInput, FileInstallOkResponse, FileInstallOutput, FileInstallRequest, GenericBadRequest
@docs GenericBadRequestResponse, GenericError, GenericErrorResponse, GenericUnauthorizedResponse
@docs PlayerSyncInput, PlayerSyncOkResponse, PlayerSyncOutput, PlayerSyncRequest, ServerLoginInput
@docs ServerLoginOkResponse, ServerLoginOutput, ServerLoginRequest


## Errors

@docs FileInstall_Error, PlayerSync_Error, ServerLogin_Error

-}
type PlayerSync_Error
    = PlayerSync_400 GenericBadRequestResponse


type alias FileInstall_Error =
    Never


type alias ServerLogin_Error =
    Never


type alias ServerLoginOutput =
    {}


type alias ServerLoginInput =
    { tunnel_id : Maybe TunnelID }


type alias PlayerSyncOutput =
    {}


type alias PlayerSyncInput =
    { token : Maybe String }


type alias GenericError =
    { details : Maybe String, msg : String }


type alias GenericBadRequest =
    { details : Maybe String, msg : String }


type alias FileInstallOutput =
    {}


type alias FileInstallInput =
    {}


type alias ServerLoginOkResponse =
    { data : ServerLoginOutput }


type alias PlayerSyncOkResponse =
    { data : PlayerSyncOutput }


type alias GenericUnauthorizedResponse =
    ()


type alias GenericErrorResponse =
    { error : GenericError }


type alias GenericBadRequestResponse =
    { error : GenericBadRequest }


type alias FileInstallOkResponse =
    { data : FileInstallOutput }


type alias ServerLoginRequest =
    ServerLoginInput


type alias PlayerSyncRequest =
    PlayerSyncInput


type alias FileInstallRequest =
    FileInstallInput
