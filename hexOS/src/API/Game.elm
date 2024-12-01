module API.Game exposing (..)

import API.Game.Api as Api
import API.Game.Types as GameTypes
import API.Types as Types
    exposing
        ( Error(..)
        , InputConfig
        , InputContext
        , InputToken(..)
        )
import API.Utils exposing (PrivateErrType(..), dataMapper, extractBody, extractBodyAndParams, mapError, mapResponse)
import OpenApi.Common
import Task exposing (Task)



-- Utils


gameServer : String
gameServer =
    -- TODO
    "http://localhost:4001"


getContext : String -> String -> InputContext
getContext server authToken =
    { server = gameServer
    , token = InputToken authToken
    }



-- Requests
-- Requests > ServerLogin


serverLoginConfig : InputContext -> String -> String -> Maybe Int -> InputConfig Types.ServerLoginInput
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
