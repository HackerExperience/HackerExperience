module API.Lobby.Types exposing
    ( GenericError, GenericErrorResponse, GenericUnauthorizedResponse, Log, Server, UserLoginInput
    , UserLoginOkResponse, UserLoginOutput, UserLoginRequest, UserRegisterInput, UserRegisterOkResponse
    , UserRegisterOutput, UserRegisterRequest
    , UserLogin_Error(..), UserRegister_Error(..)
    )

{-|


## Aliases

@docs GenericError, GenericErrorResponse, GenericUnauthorizedResponse, Log, Server, UserLoginInput
@docs UserLoginOkResponse, UserLoginOutput, UserLoginRequest, UserRegisterInput, UserRegisterOkResponse
@docs UserRegisterOutput, UserRegisterRequest


## Errors

@docs UserLogin_Error, UserRegister_Error

-}


type UserLogin_Error
    = UserLogin_401 GenericUnauthorizedResponse
    | UserLogin_422 GenericErrorResponse


type UserRegister_Error
    = UserRegister_422 GenericErrorResponse


type alias UserRegisterOutput =
    { endpoints : Maybe Server, gateways : List Server }


type alias UserRegisterInput =
    { todo_empty_body : String }


type alias UserLoginOutput =
    { token : String }


type alias UserLoginInput =
    { email : String, password : String }


type alias Server =
    { logs : List Log, nip : String }


type alias Log =
    { id : String }


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
