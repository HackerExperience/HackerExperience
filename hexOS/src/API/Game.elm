module API.Game exposing (..)

import API.Game.Api as Api
import API.Game.Types as GameTypes
import API.Types as Types
    exposing
        ( Error(..)
        , InputConfig
        , InputContext
        )
import API.Utils exposing (PrivateErrType(..), dataMapper, extractBodyAndParams, mapError, mapResponse)
import Game.Model.FileID exposing (FileID)
import Game.Model.InstallationID exposing (InstallationID)
import Game.Model.LogID exposing (LogID)
import Game.Model.NIP exposing (NIP)
import Game.Model.ServerID exposing (ServerID)
import Game.Model.SoftwareType as SoftwareType exposing (SoftwareType)
import Game.Model.TunnelID exposing (TunnelID)
import Task exposing (Task)



-- Requests
-- Requests > File > Delete


fileDeleteConfig : InputContext -> NIP -> FileID -> Maybe TunnelID -> InputConfig Types.FileDeleteInput
fileDeleteConfig ctx nip fileId tunnelId =
    let
        input =
            { body = { tunnel_id = tunnelId }
            , params = { nip = nip, file_id = fileId }
            }
    in
    { server = ctx.server, input = input, authToken = ctx.token }


fileDeleteTask :
    InputConfig Types.FileDeleteInput
    -> Task (Error Types.FileDeleteError) GameTypes.FileDeleteOutput
fileDeleteTask config =
    Api.fileDeleteTask (extractBodyAndParams config)
        |> mapResponse dataMapper
        |> mapError
            (\apiError ->
                case apiError of
                    -- TODO
                    LegitimateError _ ->
                        InternalError

                    UnexpectedError ->
                        InternalError
            )



-- Requests > File > Install


fileInstallConfig : InputContext -> NIP -> FileID -> InputConfig Types.FileInstallInput
fileInstallConfig ctx nip fileId =
    let
        input =
            { body = {}
            , params = { nip = nip, file_id = fileId }
            }
    in
    { server = ctx.server, input = input, authToken = ctx.token }


fileInstallTask :
    InputConfig Types.FileInstallInput
    -> Task (Error Types.FileInstallError) GameTypes.FileInstallOutput
fileInstallTask config =
    Api.fileInstallTask (extractBodyAndParams config)
        |> mapResponse dataMapper
        |> mapError
            (\apiError ->
                case apiError of
                    -- TODO
                    LegitimateError _ ->
                        InternalError

                    UnexpectedError ->
                        InternalError
            )



-- Requests > Installation > Uninstall


installationUninstallConfig :
    InputContext
    -> NIP
    -> InstallationID
    -> InputConfig Types.InstallationUninstallInput
installationUninstallConfig ctx nip installationId =
    let
        input =
            { body = {}
            , params = { nip = nip, installation_id = installationId }
            }
    in
    { server = ctx.server, input = input, authToken = ctx.token }


installationUninstallTask :
    InputConfig Types.InstallationUninstallInput
    -> Task (Error Types.InstallationUninstallError) GameTypes.InstallationUninstallOutput
installationUninstallTask config =
    Api.installationUninstallTask (extractBodyAndParams config)
        |> mapResponse dataMapper
        |> mapError
            (\apiError ->
                case apiError of
                    -- TODO
                    LegitimateError _ ->
                        InternalError

                    UnexpectedError ->
                        InternalError
            )



-- Requests > Log > Delete


logDeleteConfig : InputContext -> NIP -> LogID -> Maybe TunnelID -> InputConfig Types.LogDeleteInput
logDeleteConfig ctx nip logId tunnelId =
    let
        input =
            { body = { tunnel_id = tunnelId }
            , params = { nip = nip, log_id = logId }
            }
    in
    { server = ctx.server, input = input, authToken = ctx.token }


logDeleteTask :
    InputConfig Types.LogDeleteInput
    -> Task (Error Types.LogDeleteError) GameTypes.LogDeleteOutput
logDeleteTask config =
    Api.logDeleteTask (extractBodyAndParams config)
        |> mapResponse dataMapper
        |> mapError
            (\apiError ->
                case apiError of
                    -- TODO
                    LegitimateError _ ->
                        InternalError

                    UnexpectedError ->
                        InternalError
            )



-- Requests > Log > Edit


logEditConfig :
    InputContext
    -> NIP
    -> LogID
    -> String
    -> String
    -> String
    -> Maybe TunnelID
    -> InputConfig Types.LogEditInput
logEditConfig ctx nip logId logType logDirection logData tunnelId =
    let
        input =
            { body =
                { tunnel_id = tunnelId
                , log_type = logType
                , log_direction = logDirection
                , log_data = logData
                }
            , params = { nip = nip, log_id = logId }
            }
    in
    { server = ctx.server, input = input, authToken = ctx.token }


logEditTask :
    InputConfig Types.LogEditInput
    -> Task (Error Types.LogEditError) GameTypes.LogEditOutput
logEditTask config =
    Api.logEditTask (extractBodyAndParams config)
        |> mapResponse dataMapper
        |> mapError
            (\apiError ->
                case apiError of
                    -- TODO
                    LegitimateError _ ->
                        InternalError

                    UnexpectedError ->
                        InternalError
            )



-- Requests > Server > Login


serverLoginConfig :
    InputContext
    -> NIP
    -> NIP
    -> Maybe TunnelID
    -> InputConfig Types.ServerLoginInput
serverLoginConfig ctx sourceNip targetNip tunnelId =
    let
        input =
            { body = { tunnel_id = tunnelId }
            , params = { nip = sourceNip, target_nip = targetNip }
            }
    in
    { server = ctx.server, input = input, authToken = ctx.token }


serverLoginTask :
    InputConfig Types.ServerLoginInput
    -> Task (Error Types.ServerLoginError) GameTypes.ServerLoginOutput
serverLoginTask config =
    Api.serverLoginTask (extractBodyAndParams config)
        |> mapResponse dataMapper
        |> mapError
            (\apiError ->
                case apiError of
                    -- TODO
                    LegitimateError _ ->
                        InternalError

                    UnexpectedError ->
                        InternalError
            )



-- Requests > Software > AppStoreInstall


appStoreInstallConfig :
    InputContext
    -> ServerID
    -> SoftwareType
    -> InputConfig Types.AppStoreInstallInput
appStoreInstallConfig ctx serverId softwareType =
    let
        rawSoftwareType =
            SoftwareType.typeToString softwareType

        input =
            { body = {}
            , params = { server_id = serverId, software_type = rawSoftwareType }
            }
    in
    { server = ctx.server, input = input, authToken = ctx.token }


appStoreInstallTask :
    InputConfig Types.AppStoreInstallInput
    -> Task (Error Types.AppStoreInstallError) GameTypes.AppStoreInstallOutput
appStoreInstallTask config =
    Api.appStoreInstallTask (extractBodyAndParams config)
        |> mapResponse dataMapper
        |> mapError
            (\apiError ->
                case apiError of
                    -- TODO
                    LegitimateError _ ->
                        InternalError

                    UnexpectedError ->
                        InternalError
            )
