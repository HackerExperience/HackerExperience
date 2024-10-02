module API.Lobby exposing (..)

import API.Lobby.Api as Api
import API.Lobby.Types as LobbyTypes
import API.Types as Types exposing (Error(..), InputConfig, LobbyLoginError(..), LobbyRegisterError(..))
import Http exposing (Body, Expect, Header)
import OpenApi.Common
import Task exposing (Task)


lobbyServer : String
lobbyServer =
    -- TODO
    "http://localhost:4000"


loginConfig : String -> String -> InputConfig Types.LobbyLoginBody
loginConfig email password =
    { server = lobbyServer, body = { email = email, password = password } }


loginTask config =
    Api.userLoginTask config
        |> mapResponse genericDataMapper
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


mapResponse : (a -> b) -> Task e a -> Task e b
mapResponse mapper =
    Task.andThen (\resp -> Task.succeed (mapper resp))


genericDataMapper : { b | data : a } -> a
genericDataMapper =
    \{ data } -> data


mapError : (PrivateErrType a -> Error b) -> Task (OpenApi.Common.Error a x) r -> Task (Error b) r
mapError mapper =
    Task.onError
        (\apiError ->
            case apiError of
                OpenApi.Common.KnownBadStatus _ appError ->
                    Task.fail <| mapper (LegitimateError appError)

                _ ->
                    Task.fail <| mapper UnexpectedError
        )



-- Error handler


type PrivateErrType a
    = LegitimateError a
    | UnexpectedError


withErrorHandler : Task (OpenApi.Common.Error x y) a -> Task (PrivateErrType x) a
withErrorHandler =
    Task.onError errorHandler


errorHandler : OpenApi.Common.Error x y -> Task (PrivateErrType x) a
errorHandler error =
    case error of
        OpenApi.Common.KnownBadStatus _ appError ->
            Task.fail (LegitimateError appError)

        _ ->
            Task.fail UnexpectedError
