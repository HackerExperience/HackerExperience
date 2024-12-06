module API.Lobby exposing (..)

import API.Lobby.Api as Api
import API.Lobby.Types as LobbyTypes
import API.Types as Types
    exposing
        ( Error(..)
        , InputConfig
        , InputContext
        , LobbyLoginError(..)
        )
import API.Utils exposing (PrivateErrType(..), dataMapper, extractBodyNH, mapError, mapResponse)
import Task exposing (Task)


loginConfig : InputContext -> String -> String -> InputConfig Types.LobbyLoginInput
loginConfig ctx email password =
    let
        input =
            { body = { email = email, password = password } }
    in
    { server = ctx.server, input = input, authToken = ctx.token }


loginTask : InputConfig Types.LobbyLoginInput -> Task (Error LobbyLoginError) LobbyTypes.UserLoginOutput
loginTask config =
    Api.userLoginTask (extractBodyNH config)
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
