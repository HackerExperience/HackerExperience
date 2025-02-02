-- This is an auto-generated file; manual changes will be overwritten!


module API.Game.Api exposing
    ( fileDeleteTask, fileInstallTask, fileTransferTask, installationUninstallTask, playerSyncTask
    , serverLoginTask
    )

{-|


## Operations

@docs fileDeleteTask, fileInstallTask, fileTransferTask, installationUninstallTask, playerSyncTask
@docs serverLoginTask

-}

import API.Game.Json
import API.Game.Types
import Dict
import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ServerID as ServerID exposing (ServerID(..))
import Game.Model.TunnelID as TunnelID exposing (TunnelID(..))
import Http
import Json.Decode
import Json.Encode
import OpenApi.Common
import Task
import Url.Builder


playerSyncTask :
    { server : String, body : API.Game.Types.PlayerSyncRequest }
    -> Task.Task (OpenApi.Common.Error API.Game.Types.GenericBadRequestResponse String) API.Game.Types.PlayerSyncOkResponse
playerSyncTask config =
    Http.task
        { url =
            Url.Builder.crossOrigin config.server [ "v1", "player", "sync" ] []
        , method = "POST"
        , headers = []
        , resolver =
            OpenApi.Common.jsonResolverCustom
                (Dict.fromList
                    [ ( "400", API.Game.Json.decodeGenericBadRequestResponse )
                    ]
                )
                API.Game.Json.decodePlayerSyncOkResponse
        , body =
            Http.jsonBody (API.Game.Json.encodePlayerSyncRequest config.body)
        , timeout = Nothing
        }


fileDeleteTask :
    { server : String
    , authorization : { authorization : String }
    , body : API.Game.Types.FileDeleteRequest
    , params : { nip : NIP, file_id : String }
    }
    -> Task.Task (OpenApi.Common.Error e String) API.Game.Types.FileDeleteOkResponse
fileDeleteTask config =
    Http.task
        { url =
            Url.Builder.crossOrigin
                config.server
                [ "v1"
                , "server"
                , NIP.toString config.params.nip
                , "file"
                , config.params.file_id
                , "delete"
                ]
                []
        , method = "POST"
        , headers =
            [ Http.header "Authorization" config.authorization.authorization ]
        , resolver =
            OpenApi.Common.jsonResolverCustom
                (Dict.fromList [])
                API.Game.Json.decodeFileDeleteOkResponse
        , body =
            Http.jsonBody (API.Game.Json.encodeFileDeleteRequest config.body)
        , timeout = Nothing
        }


fileInstallTask :
    { server : String
    , authorization : { authorization : String }
    , body : API.Game.Types.FileInstallRequest
    , params : { nip : NIP, file_id : String }
    }
    -> Task.Task (OpenApi.Common.Error e String) API.Game.Types.FileInstallOkResponse
fileInstallTask config =
    Http.task
        { url =
            Url.Builder.crossOrigin
                config.server
                [ "v1"
                , "server"
                , NIP.toString config.params.nip
                , "file"
                , config.params.file_id
                , "install"
                ]
                []
        , method = "POST"
        , headers =
            [ Http.header "Authorization" config.authorization.authorization ]
        , resolver =
            OpenApi.Common.jsonResolverCustom
                (Dict.fromList [])
                API.Game.Json.decodeFileInstallOkResponse
        , body =
            Http.jsonBody (API.Game.Json.encodeFileInstallRequest config.body)
        , timeout = Nothing
        }


fileTransferTask :
    { server : String
    , authorization : { authorization : String }
    , body : API.Game.Types.FileTransferRequest
    , params : { nip : NIP, file_id : String }
    }
    -> Task.Task (OpenApi.Common.Error e String) API.Game.Types.FileTransferOkResponse
fileTransferTask config =
    Http.task
        { url =
            Url.Builder.crossOrigin
                config.server
                [ "v1"
                , "server"
                , NIP.toString config.params.nip
                , "file"
                , config.params.file_id
                , "transfer"
                ]
                []
        , method = "POST"
        , headers =
            [ Http.header "Authorization" config.authorization.authorization ]
        , resolver =
            OpenApi.Common.jsonResolverCustom
                (Dict.fromList [])
                API.Game.Json.decodeFileTransferOkResponse
        , body =
            Http.jsonBody (API.Game.Json.encodeFileTransferRequest config.body)
        , timeout = Nothing
        }


installationUninstallTask :
    { server : String
    , authorization : { authorization : String }
    , body : API.Game.Types.InstallationUninstallRequest
    , params : { nip : NIP, installation_id : String }
    }
    -> Task.Task (OpenApi.Common.Error e String) API.Game.Types.InstallationUninstallOkResponse
installationUninstallTask config =
    Http.task
        { url =
            Url.Builder.crossOrigin
                config.server
                [ "v1"
                , "server"
                , NIP.toString config.params.nip
                , "installation"
                , config.params.installation_id
                , "uninstall"
                ]
                []
        , method = "POST"
        , headers =
            [ Http.header "Authorization" config.authorization.authorization ]
        , resolver =
            OpenApi.Common.jsonResolverCustom
                (Dict.fromList [])
                API.Game.Json.decodeInstallationUninstallOkResponse
        , body =
            Http.jsonBody
                (API.Game.Json.encodeInstallationUninstallRequest config.body)
        , timeout = Nothing
        }


serverLoginTask :
    { server : String
    , authorization : { authorization : String }
    , body : API.Game.Types.ServerLoginRequest
    , params : { nip : NIP, target_nip : NIP }
    }
    -> Task.Task (OpenApi.Common.Error e String) API.Game.Types.ServerLoginOkResponse
serverLoginTask config =
    Http.task
        { url =
            Url.Builder.crossOrigin
                config.server
                [ "v1"
                , "server"
                , NIP.toString config.params.nip
                , "login"
                , NIP.toString config.params.target_nip
                ]
                []
        , method = "POST"
        , headers =
            [ Http.header "Authorization" config.authorization.authorization ]
        , resolver =
            OpenApi.Common.jsonResolverCustom
                (Dict.fromList [])
                API.Game.Json.decodeServerLoginOkResponse
        , body =
            Http.jsonBody (API.Game.Json.encodeServerLoginRequest config.body)
        , timeout = Nothing
        }
