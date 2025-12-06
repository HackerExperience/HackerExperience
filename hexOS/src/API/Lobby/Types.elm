module API.Lobby.Types exposing
    ( GenericBadRequest, GenericBadRequestResponse, GenericError, GenericErrorResponse
    , GenericUnauthorizedResponse, UserLoginInput, UserLoginOkResponse, UserLoginOutput, UserLoginRequest
    , UserRegisterInput, UserRegisterOkResponse, UserRegisterOutput, UserRegisterRequest
    , UserLogin_Error(..), UserRegister_Error(..)
    )

{-|


## Aliases

@docs GenericBadRequest, GenericBadRequestResponse, GenericError, GenericErrorResponse
@docs GenericUnauthorizedResponse, UserLoginInput, UserLoginOkResponse, UserLoginOutput, UserLoginRequest
@docs UserRegisterInput, UserRegisterOkResponse, UserRegisterOutput, UserRegisterRequest


## Errors

@docs UserLogin_Error, UserRegister_Error

-}


type UserLogin_Error
    = UserLogin_400 GenericBadRequestResponse
    | UserLogin_401 GenericUnauthorizedResponse
    | UserLogin_422 GenericErrorResponse


type UserRegister_Error
    = UserRegister_400 GenericBadRequestResponse
    | UserRegister_422 GenericErrorResponse


type alias UserRegisterOutput =
    { id : String }


type alias UserRegisterInput =
    { email : String, password : String, username : String }


type alias UserLoginOutput =
    { id : String, token : String, username : String }


type alias UserLoginInput =
    { email : String, password : String }


type alias GenericError =
    { details : Maybe String, msg : String }


type alias GenericBadRequest =
    { details : Maybe String, msg : String }


type alias UserRegisterOkResponse =
    { data : UserRegisterOutput }


type alias UserLoginOkResponse =
    { data : UserLoginOutput }


type alias GenericUnauthorizedResponse =
    ()


type alias GenericErrorResponse =
    { error : GenericError }


type alias GenericBadRequestResponse =
    { error : GenericBadRequest }


type alias UserRegisterRequest =
    UserRegisterInput


type alias UserLoginRequest =
    UserLoginInput
