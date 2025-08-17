-- This is an auto-generated file; manual changes will be overwritten!


module API.Game.Api exposing
    ( appStoreInstallTask, fileDeleteTask, fileInstallTask, fileTransferTask, installationUninstallTask
    , logDeleteTask, logEditTask, playerSyncTask, serverLoginTask
    )

{-|


## Operations

@docs appStoreInstallTask, fileDeleteTask, fileInstallTask, fileTransferTask, installationUninstallTask
@docs logDeleteTask, logEditTask, playerSyncTask, serverLoginTask

-}

import API.Game.Json
import API.Game.Types
import Dict
import Game.Model.FileID as FileID exposing (FileID(..))
import Game.Model.InstallationID as InstallationID exposing (InstallationID(..))
import Game.Model.LogID as LogID exposing (LogID(..))
import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ProcessID as ProcessID exposing (ProcessID(..))
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
    , params : { file_id : FileID, nip : NIP }
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
                , FileID.toString config.params.file_id
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
    , params : { file_id : FileID, nip : NIP }
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
                , FileID.toString config.params.file_id
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
    , params : { file_id : FileID, nip : NIP }
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
                , FileID.toString config.params.file_id
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
    , params : { installation_id : InstallationID, nip : NIP }
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
                , InstallationID.toString config.params.installation_id
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


logDeleteTask :
    { server : String
    , authorization : { authorization : String }
    , body : API.Game.Types.LogDeleteRequest
    , params : { log_id : LogID, nip : NIP }
    }
    -> Task.Task (OpenApi.Common.Error e String) API.Game.Types.LogDeleteOkResponse
logDeleteTask config =
    Http.task
        { url =
            Url.Builder.crossOrigin
                config.server
                [ "v1"
                , "server"
                , NIP.toString config.params.nip
                , "log"
                , LogID.toString config.params.log_id
                , "delete"
                ]
                []
        , method = "POST"
        , headers =
            [ Http.header "Authorization" config.authorization.authorization ]
        , resolver =
            OpenApi.Common.jsonResolverCustom
                (Dict.fromList [])
                API.Game.Json.decodeLogDeleteOkResponse
        , body =
            Http.jsonBody (API.Game.Json.encodeLogDeleteRequest config.body)
        , timeout = Nothing
        }


logEditTask :
    { server : String
    , authorization : { authorization : String }
    , body : API.Game.Types.LogEditRequest
    , params : { log_id : LogID, nip : NIP }
    }
    -> Task.Task (OpenApi.Common.Error e String) API.Game.Types.LogEditOkResponse
logEditTask config =
    Http.task
        { url =
            Url.Builder.crossOrigin
                config.server
                [ "v1"
                , "server"
                , NIP.toString config.params.nip
                , "log"
                , LogID.toString config.params.log_id
                , "edit"
                ]
                []
        , method = "POST"
        , headers =
            [ Http.header "Authorization" config.authorization.authorization ]
        , resolver =
            OpenApi.Common.jsonResolverCustom
                (Dict.fromList [])
                API.Game.Json.decodeLogEditOkResponse
        , body = Http.jsonBody (API.Game.Json.encodeLogEditRequest config.body)
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


appStoreInstallTask :
    { server : String
    , authorization : { authorization : String }
    , body : API.Game.Types.AppStoreInstallRequest
    , params : { server_id : ServerID, software_type : String }
    }
    -> Task.Task (OpenApi.Common.Error e String) API.Game.Types.AppStoreInstallOkResponse
appStoreInstallTask config =
    Http.task
        { url =
            Url.Builder.crossOrigin
                config.server
                [ "v1"
                , "server"
                , ServerID.toString config.params.server_id
                , "appstore"
                , config.params.software_type
                , "install"
                ]
                []
        , method = "POST"
        , headers =
            [ Http.header "Authorization" config.authorization.authorization ]
        , resolver =
            OpenApi.Common.jsonResolverCustom
                (Dict.fromList [])
                API.Game.Json.decodeAppStoreInstallOkResponse
        , body =
            Http.jsonBody
                (API.Game.Json.encodeAppStoreInstallRequest config.body)
        , timeout = Nothing
        }
