module API.Types exposing (..)

import API.Lobby.Types as LobbyTypes



-- Shared types


type alias InputConfig body =
    { body : body, server : String }


type Error a
    = AppError a
    | InternalError



-- Lobby
-- Lobby > Login


type LobbyLoginError
    = LobbyLoginUnauthorized


type alias LobbyLoginResponse =
    LobbyTypes.UserLoginOutput


type alias LobbyLoginBody =
    LobbyTypes.UserLoginRequest


type alias LobbyLoginResult =
    Result (Error LobbyLoginError) LobbyLoginResponse



-- Lobby > Register


type LobbyRegisterError
    = LobbyRegisterUnauthorized


type alias LobbyRegisterResponse =
    LobbyTypes.UserRegisterOutput
