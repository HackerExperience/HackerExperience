module API.Lobby exposing (..)

import API.Lobby.Api as Api
import API.Lobby.Types as LobbyTypes
import API.Types as Types
    exposing
        ( Error(..)
        , InputConfig
        , LobbyLoginError(..)
        )
import API.Utils exposing (PrivateErrType(..), dataMapper, extractBody, extractBodyAndParams, mapError, mapResponse)
import OpenApi.Common
import Task exposing (Task)


lobbyServer : String
lobbyServer =
    -- TODO
    "http://localhost:4000"


loginConfig : String -> String -> InputConfig Types.LobbyLoginInput
loginConfig email password =
    let
        input =
            { body = { email = email, password = password } }
    in
    { server = lobbyServer, input = input }


loginTask : InputConfig Types.LobbyLoginInput -> Task (Error LobbyLoginError) LobbyTypes.UserLoginOutput
loginTask config =
    Api.userLoginTask (extractBody config)
        |> mapResponse dataMapper
        |> mapError
            (\apiError ->
                case apiError of
                    LegitimateError (LobbyTypes.UserLogin_400 _) ->
                        InternalError

                    LegitimateError (LobbyTypes.UserLogin_401 _) ->
                        AppError LobbyLoginUnauthorized

                    LegitimateError (LobbyTypes.UserLogin_422 { error }) ->
                        case error.msg of
                            "bad_password" ->
                                AppError LobbyLoginUnauthorized

                            _ ->
                                InternalError

                    UnexpectedError ->
                        InternalError
            )
