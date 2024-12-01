module API.Game exposing (..)

import API.Game.Api as Api
import API.Game.Types as GameTypes
import API.Types as Types
    exposing
        ( Error(..)
        , InputConfig
        )
import API.Utils exposing (PrivateErrType(..), dataMapper, extractBody, extractBodyAndParams, mapError, mapResponse)
import OpenApi.Common
import Task exposing (Task)


gameServer : String
gameServer =
    -- TODO
    "http://localhost:4001"


serverLoginConfig : String -> String -> Maybe Int -> InputConfig Types.ServerLoginInput
serverLoginConfig sourceNip targetNip tunnelId =
    let
        input =
            { body = { tunnel_id = tunnelId }
            , params = { nip = sourceNip, target_nip = targetNip }
            }
    in
    { server = gameServer, input = input }


serverLoginTask : InputConfig Types.ServerLoginInput -> Task (Error Types.ServerLoginError) GameTypes.ServerLoginOutput
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
