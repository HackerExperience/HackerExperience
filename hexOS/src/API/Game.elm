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
import Game.Model.LogID exposing (LogID)
import Game.Model.NIP exposing (NIP)
import Game.Model.TunnelID exposing (TunnelID)
import Task exposing (Task)



-- Requests
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



-- Requests > Server > Login


serverLoginConfig : InputContext -> NIP -> NIP -> Maybe TunnelID -> InputConfig Types.ServerLoginInput
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
