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
import Game.Model.NIP as NIP exposing (NIP)
import Task exposing (Task)



-- Requests
-- Requests > ServerLogin


serverLoginConfig : InputContext -> NIP -> NIP -> Maybe Int -> InputConfig Types.ServerLoginInput
serverLoginConfig ctx sourceNip targetNip tunnelId =
    let
        input =
            { body = { tunnel_id = tunnelId }
            , params = { nip = NIP.toString sourceNip, target_nip = NIP.toString targetNip }
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
