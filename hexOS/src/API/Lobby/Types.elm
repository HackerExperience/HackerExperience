module API.Lobby.Types exposing
    ( EmptyOkResponse, GenericError, GenericErrorModel, LoginOkResponse, LoginUser, LoginUserRequest, NewUser
    , NewUserRequest, Unauthorized, User, UserLoginResponse
    , CreateUser_Error(..), Login_Error(..)
    )

{-|


## Aliases

@docs EmptyOkResponse, GenericError, GenericErrorModel, LoginOkResponse, LoginUser, LoginUserRequest, NewUser
@docs NewUserRequest, Unauthorized, User, UserLoginResponse


## Errors

@docs CreateUser_Error, Login_Error

-}


type CreateUser_Error
    = CreateUser_422 GenericError


type Login_Error
    = Login_401 Unauthorized
    | Login_422 GenericError


type alias UserLoginResponse =
    { token : String }


type alias User =
    { bio : Maybe String
    , email : String
    , image : String
    , token : String
    , username : String
    }


type alias NewUser =
    { email : String, password : String, username : String }


type alias LoginUser =
    { email : String, password : String }


type alias GenericErrorModel =
    { error : String }


type alias Unauthorized =
    ()


type alias LoginOkResponse =
    { data : UserLoginResponse }


type alias GenericError =
    GenericErrorModel


type alias EmptyOkResponse =
    ()


type alias NewUserRequest =
    { user : NewUser }


type alias LoginUserRequest =
    LoginUser
