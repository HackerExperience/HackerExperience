module API.Types exposing (..)

import API.Game.Types as GameTypes
import API.Lobby.Types as LobbyTypes



-- Shared types


type InputToken
    = InputToken String
    | NoToken


type alias InputConfig input =
    { server : String
    , input : input
    , authToken : InputToken
    }


type alias InputContext =
    { token : InputToken
    , server : String
    }


type Error a
    = AppError a
    | InternalError



-- Common


type alias AuthorizationHeader =
    { authorization : String }



-- Game
-- Game > ServerLogin


type alias ServerLoginInput =
    { body : GameTypes.ServerLoginRequest
    , params : ServerLoginParams
    }


type alias ServerLoginParams =
    { nip : String, target_nip : String }


type alias ServerLoginError =
    GameTypes.GenericError


type alias ServerLoginResult =
    Result (Error ServerLoginError) GameTypes.ServerLoginOutput



-- Lobby
-- Lobby > Login


type LobbyLoginError
    = LobbyLoginUnauthorized


type alias LobbyLoginInput =
    { body : LobbyTypes.UserLoginRequest }


type alias LobbyLoginResult =
    Result (Error LobbyLoginError) LobbyTypes.UserLoginOutput



-- Lobby > Register


type LobbyRegisterError
    = LobbyRegisterUnauthorized


type alias LobbyRegisterResponse =
    LobbyTypes.UserRegisterOutput



-- Utils
-- TODO: Maybe move to API.Utils?
