module API.Types exposing (..)

import API.Game.Types as GameTypes
import API.Lobby.Types as LobbyTypes
import Game.Model.LogID exposing (LogID)
import Game.Model.NIP exposing (NIP)



-- Shared types


type APIServer
    = ServerLobby
    | ServerGameSP
    | ServerGameMP


type ServerURL
    = ServerURL String


type InputToken
    = InputToken String
    | NoToken


type alias InputConfig input =
    { server : ServerURL
    , input : input
    , authToken : InputToken
    }


type alias InputContext =
    { token : InputToken
    , server : ServerURL
    }


type Error a
    = AppError a
    | InternalError



-- Common


type alias AuthorizationHeader =
    { authorization : String }



-- Game
-- Game > Log > Delete


type alias LogDeleteInput =
    { body : GameTypes.LogDeleteRequest
    , params : LogDeleteParams
    }


type alias LogDeleteParams =
    { nip : NIP, log_id : LogID }


type alias LogDeleteError =
    GameTypes.GenericError


type alias LogDeleteResult =
    Result (Error LogDeleteError) GameTypes.LogDeleteOutput



-- Game > Log > Edit


type alias LogEditInput =
    { body : GameTypes.LogEditRequest
    , params : LogEditParams
    }


type alias LogEditParams =
    { nip : NIP, log_id : LogID }


type alias LogEditError =
    GameTypes.GenericError


type alias LogEditResult =
    Result (Error LogEditError) GameTypes.LogEditOutput



-- Game > Server > Login


type alias ServerLoginInput =
    { body : GameTypes.ServerLoginRequest
    , params : ServerLoginParams
    }


type alias ServerLoginParams =
    { nip : NIP, target_nip : NIP }


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
