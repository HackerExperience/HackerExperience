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


login :
    String
    -> String
    -> Task (Error LoginError) Types.UserLoginResponse
login email password =
    let
        config =
            { server = "http://localhost:4000/v1"
            , body = { email = email, password = password }
            }
    in
    Api.loginTask config
        |> withInnerData
        |> withErrorHandler
        |> Task.onError
            (\apiError ->
                case apiError of
                    LegitimateError (Types.Login_401 _) ->
                        Task.fail (AppError Unauthorized)

                    LegitimateError (Types.Login_422 { error }) ->
                        case error of
                            "bad_password" ->
                                Task.fail (AppError Unauthorized)

                            _ ->
                                Task.fail InternalError

                    UnexpectedError ->
                        Task.fail InternalError
            )


withInnerData : Task x { a | data : b } -> Task x b
withInnerData =
    Task.andThen (\response -> Task.succeed response.data)



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
