module API.Game.Api exposing (playerSyncTask, serverLoginTask)

{-|


## Operations

@docs playerSyncTask, serverLoginTask

-}

import API.Game.Json
import API.Game.Types
import Dict
import Http
import Json.Decode
import Json.Encode
import OpenApi.Common
import Task
import Url.Builder


playerSyncTask :
    { server : String, body : API.Game.Types.PlayerSyncRequest }
    -> Task.Task (OpenApi.Common.Error API.Game.Types.PlayerSync_Error String) API.Game.Types.PlayerSyncOkResponse
playerSyncTask config =
    Http.task
        { url =
            Url.Builder.crossOrigin config.server [ "v1", "player", "sync" ] []
        , method = "POST"
        , headers = []
        , resolver =
            OpenApi.Common.jsonResolverCustom
                (Dict.fromList
                    [ ( "400"
                      , Json.Decode.map
                            API.Game.Types.PlayerSync_400
                            API.Game.Json.decodeGenericBadRequestResponse
                      )
                    ]
                )
                API.Game.Json.decodePlayerSyncOkResponse
        , body =
            Http.jsonBody (API.Game.Json.encodePlayerSyncRequest config.body)
        , timeout = Nothing
        }


serverLoginTask :
    { server : String
    , body : API.Game.Types.ServerLoginRequest
    , params : { nip : String, target_nip : String }
    }
    -> Task.Task (OpenApi.Common.Error API.Game.Types.ServerLogin_Error String) API.Game.Types.ServerLoginOkResponse
serverLoginTask config =
    Http.task
        { url =
            Url.Builder.crossOrigin
                config.server
                [ "v1"
                , "server"
                , config.params.nip
                , "login"
                , config.params.target_nip
                ]
                []
        , method = "POST"
        , headers = []
        , resolver =
            OpenApi.Common.jsonResolverCustom
                (Dict.fromList [])
                API.Game.Json.decodeServerLoginOkResponse
        , body =
            Http.jsonBody (API.Game.Json.encodeServerLoginRequest config.body)
        , timeout = Nothing
        }
