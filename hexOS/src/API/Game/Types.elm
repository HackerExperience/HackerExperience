module API.Game.Types exposing
    ( GenericBadRequest, GenericBadRequestResponse, GenericError, GenericErrorResponse
    , GenericUnauthorizedResponse, PlayerSyncInput, PlayerSyncOkResponse, PlayerSyncOutput, PlayerSyncRequest
    , ServerLoginInput, ServerLoginOkResponse, ServerLoginOutput, ServerLoginRequest
    , PlayerSync_Error(..), ServerLogin_Error
    )

{-|


## Aliases

@docs GenericBadRequest, GenericBadRequestResponse, GenericError, GenericErrorResponse
@docs GenericUnauthorizedResponse, PlayerSyncInput, PlayerSyncOkResponse, PlayerSyncOutput, PlayerSyncRequest
@docs ServerLoginInput, ServerLoginOkResponse, ServerLoginOutput, ServerLoginRequest


## Errors

@docs PlayerSync_Error, ServerLogin_Error

-}


type PlayerSync_Error
    = PlayerSync_400 GenericBadRequestResponse


type alias ServerLogin_Error =
    Never


type alias ServerLoginOutput =
    {}


type alias ServerLoginInput =
    { tunnel_id : Maybe Int }


type alias PlayerSyncOutput =
    {}


type alias PlayerSyncInput =
    { token : Maybe String }


type alias GenericError =
    { details : Maybe String, msg : String }


type alias GenericBadRequest =
    { details : Maybe String, msg : String }


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


type alias ServerLoginRequest =
    ServerLoginInput


type alias PlayerSyncRequest =
    PlayerSyncInput
