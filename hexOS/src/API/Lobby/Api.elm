module API.Lobby.Api exposing (createUser, createUserTask, login, loginTask)

{-|


## User and Authentication

@docs createUser, createUserTask, login, loginTask

-}

import API.Lobby.Json
import API.Lobby.Types
import Dict
import Http
import Json.Decode
import Json.Encode
import OpenApi.Common
import Task
import Url.Builder


{-| Register a new user
-}
createUser config =
    Http.request
        { url = Url.Builder.crossOrigin config.server [ "user" ] []
        , method = "POST"
        , headers = []
        , expect =
            OpenApi.Common.expectJsonCustom
                config.toMsg
                (Dict.fromList
                    [ ( "422"
                      , Json.Decode.map
                            API.Lobby.Types.CreateUser_422
                            API.Lobby.Json.decodeGenericError
                      )
                    ]
                )
                API.Lobby.Json.decodeLoginOkResponse
        , body = Http.jsonBody (API.Lobby.Json.encodeNewUserRequest config.body)
        , timeout = Nothing
        , tracker = Nothing
        }


{-| Register a new user
-}
createUserTask :
    { server : String, body : API.Lobby.Types.NewUserRequest }
    -> Task.Task (OpenApi.Common.Error API.Lobby.Types.CreateUser_Error String) API.Lobby.Types.LoginOkResponse
createUserTask config =
    Http.task
        { url = Url.Builder.crossOrigin config.server [ "user" ] []
        , method = "POST"
        , headers = []
        , resolver =
            OpenApi.Common.jsonResolverCustom
                (Dict.fromList
                    [ ( "422"
                      , Json.Decode.map
                            API.Lobby.Types.CreateUser_422
                            API.Lobby.Json.decodeGenericError
                      )
                    ]
                )
                API.Lobby.Json.decodeLoginOkResponse
        , body = Http.jsonBody (API.Lobby.Json.encodeNewUserRequest config.body)
        , timeout = Nothing
        }


{-| Existing user login

Login for existing user

-}
login config =
    Http.request
        { url = Url.Builder.crossOrigin config.server [ "user", "login" ] []
        , method = "POST"
        , headers = []
        , expect =
            OpenApi.Common.expectJsonCustom
                config.toMsg
                (Dict.fromList
                    [ ( "401"
                      , Json.Decode.map
                            API.Lobby.Types.Login_401
                            API.Lobby.Json.decodeUnauthorized
                      )
                    , ( "422"
                      , Json.Decode.map
                            API.Lobby.Types.Login_422
                            API.Lobby.Json.decodeGenericError
                      )
                    ]
                )
                API.Lobby.Json.decodeLoginOkResponse
        , body =
            Http.jsonBody (API.Lobby.Json.encodeLoginUserRequest config.body)
        , timeout = Nothing
        , tracker = Nothing
        }


{-| Existing user login

Login for existing user

-}
loginTask :
    { server : String, body : API.Lobby.Types.LoginUserRequest }
    -> Task.Task (OpenApi.Common.Error API.Lobby.Types.Login_Error String) API.Lobby.Types.LoginOkResponse
loginTask config =
    Http.task
        { url = Url.Builder.crossOrigin config.server [ "user", "login" ] []
        , method = "POST"
        , headers = []
        , resolver =
            OpenApi.Common.jsonResolverCustom
                (Dict.fromList
                    [ ( "401"
                      , Json.Decode.map
                            API.Lobby.Types.Login_401
                            API.Lobby.Json.decodeUnauthorized
                      )
                    , ( "422"
                      , Json.Decode.map
                            API.Lobby.Types.Login_422
                            API.Lobby.Json.decodeGenericError
                      )
                    ]
                )
                API.Lobby.Json.decodeLoginOkResponse
        , body =
            Http.jsonBody (API.Lobby.Json.encodeLoginUserRequest config.body)
        , timeout = Nothing
        }
