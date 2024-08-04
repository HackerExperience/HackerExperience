module API.Lobby exposing (..)

import API.Lobby.Api as Api
import API.Lobby.Types as Types
import OpenApi.Common
import Task exposing (Task)


type Error a
    = AppError a
    | InternalError


type LoginError
    = Unauthorized


type alias LoginResponse =
    Types.UserLoginOutput


login :
    String
    -> String
    -> Task (Error LoginError) LoginResponse
login email password =
    let
        config =
            { server = "http://localhost:4000/v1"
            , body = { email = email, password = password }
            }
    in
    Api.userLoginTask config
        |> mapResponse genericDataMapper
        |> mapError
            (\apiError ->
                case apiError of
                    LegitimateError (Types.UserLogin_401 _) ->
                        AppError Unauthorized

                    LegitimateError (Types.UserLogin_422 { error }) ->
                        case error of
                            "bad_password" ->
                                AppError Unauthorized

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
