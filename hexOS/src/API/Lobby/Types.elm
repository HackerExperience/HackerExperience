module API.Lobby.Types exposing
    ( GenericError, GenericErrorResponse, GenericUnauthorizedResponse, UserLoginInput, UserLoginOkResponse
    , UserLoginOutput, UserLoginRequest, UserRegisterInput, UserRegisterOkResponse, UserRegisterOutput
    , UserRegisterRequest
    , UserLogin_Error(..), UserRegister_Error(..)
    )

{-|


## Aliases

@docs GenericError, GenericErrorResponse, GenericUnauthorizedResponse, UserLoginInput, UserLoginOkResponse
@docs UserLoginOutput, UserLoginRequest, UserRegisterInput, UserRegisterOkResponse, UserRegisterOutput
@docs UserRegisterRequest


## Errors

@docs UserLogin_Error, UserRegister_Error

-}


type UserLogin_Error
    = UserLogin_401 GenericUnauthorizedResponse
    | UserLogin_422 GenericErrorResponse


type UserRegister_Error
    = UserRegister_422 GenericErrorResponse


type alias UserRegisterOutput =
    { id : String }


type alias UserRegisterInput =
    { email : String, password : String, username : String }


type alias UserLoginOutput =
    { token : String }


type alias UserLoginInput =
    { email : String, password : String }


type alias GenericError =
    { error : String }


type alias UserRegisterOkResponse =
    { data : UserRegisterOutput }


type alias UserLoginOkResponse =
    { data : UserLoginOutput }


type alias GenericUnauthorizedResponse =
    ()


type alias GenericErrorResponse =
    GenericError


type alias UserRegisterRequest =
    UserRegisterInput


type alias UserLoginRequest =
    UserLoginInput
