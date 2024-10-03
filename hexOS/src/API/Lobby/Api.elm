module API.Lobby.Api exposing (userLoginTask, userRegisterTask)

{-|


## Operations

@docs userLoginTask, userRegisterTask

-}

import API.Lobby.Json
import API.Lobby.Types
import Dict
import Http
import Json.Decode
import OpenApi.Common
import Task
import Url.Builder


userLoginTask :
    { server : String, body : API.Lobby.Types.UserLoginRequest }
    -> Task.Task (OpenApi.Common.Error API.Lobby.Types.UserLogin_Error String) API.Lobby.Types.UserLoginOkResponse
userLoginTask config =
    Http.task
        { url =
            Url.Builder.crossOrigin config.server [ "v1", "user", "login" ] []
        , method = "POST"
        , headers = []
        , resolver =
            OpenApi.Common.jsonResolverCustom
                (Dict.fromList
                    [ ( "400"
                      , Json.Decode.map
                            API.Lobby.Types.UserLogin_400
                            API.Lobby.Json.decodeGenericBadRequestResponse
                      )
                    , ( "401"
                      , Json.Decode.map
                            API.Lobby.Types.UserLogin_401
                            API.Lobby.Json.decodeGenericUnauthorizedResponse
                      )
                    , ( "422"
                      , Json.Decode.map
                            API.Lobby.Types.UserLogin_422
                            API.Lobby.Json.decodeGenericErrorResponse
                      )
                    ]
                )
                API.Lobby.Json.decodeUserLoginOkResponse
        , body =
            Http.jsonBody (API.Lobby.Json.encodeUserLoginRequest config.body)
        , timeout = Nothing
        }


userRegisterTask :
    { server : String, body : API.Lobby.Types.UserRegisterRequest }
    -> Task.Task (OpenApi.Common.Error API.Lobby.Types.UserRegister_Error String) API.Lobby.Types.UserRegisterOkResponse
userRegisterTask config =
    Http.task
        { url =
            Url.Builder.crossOrigin
                config.server
                [ "v1", "user", "register" ]
                []
        , method = "POST"
        , headers = []
        , resolver =
            OpenApi.Common.jsonResolverCustom
                (Dict.fromList
                    [ ( "400"
                      , Json.Decode.map
                            API.Lobby.Types.UserRegister_400
                            API.Lobby.Json.decodeGenericBadRequestResponse
                      )
                    , ( "422"
                      , Json.Decode.map
                            API.Lobby.Types.UserRegister_422
                            API.Lobby.Json.decodeGenericErrorResponse
                      )
                    ]
                )
                API.Lobby.Json.decodeUserRegisterOkResponse
        , body =
            Http.jsonBody (API.Lobby.Json.encodeUserRegisterRequest config.body)
        , timeout = Nothing
        }
