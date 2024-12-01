module API.Utils exposing
    ( PrivateErrType(..)
    , dataMapper
    , extractBody
    , extractBodyAndParams
    , extractBodyAndParamsNH
    , extractBodyNH
    , mapError
    , mapResponse
    )

import API.Types as Types exposing (Error(..), InputConfig, InputToken(..))
import OpenApi.Common
import Task exposing (Task)



-- Utils > Error handling


type PrivateErrType a
    = LegitimateError a
    | UnexpectedError


mapResponse : (a -> b) -> Task e a -> Task e b
mapResponse mapper =
    Task.map (\resp -> mapper resp)


dataMapper : { b | data : a } -> a
dataMapper =
    \{ data } -> data


mapError : (PrivateErrType a -> Error b) -> Task (OpenApi.Common.Error a x) r -> Task (Error b) r
mapError mapper =
    Task.mapError
        (\apiError ->
            case apiError of
                OpenApi.Common.KnownBadStatus _ appError ->
                    mapper (LegitimateError appError)

                _ ->
                    mapper UnexpectedError
        )


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



-- Utils > Extract input


extractBody :
    InputConfig { body : b }
    -> { server : String, body : b, authorization : { authorization : String } }
extractBody config =
    { server = config.server
    , body = config.input.body
    , authorization = { authorization = tokenToString config.authToken }
    }


{-| "No Header" variant
-}
extractBodyNH :
    InputConfig { body : b }
    -> { server : String, body : b }
extractBodyNH config =
    { server = config.server, body = config.input.body }


extractBodyAndParams :
    InputConfig { body : b, params : p }
    -> { server : String, body : b, params : p, authorization : { authorization : String } }
extractBodyAndParams config =
    { server = config.server
    , body = config.input.body
    , params = config.input.params
    , authorization = { authorization = tokenToString config.authToken }
    }


{-| "No Header" variant
-}
extractBodyAndParamsNH :
    InputConfig { body : b, params : p }
    -> { server : String, body : b, params : p }
extractBodyAndParamsNH config =
    { server = config.server
    , body = config.input.body
    , params = config.input.params
    }


tokenToString : InputToken -> String
tokenToString inputToken =
    case inputToken of
        InputToken token ->
            token

        NoToken ->
            ""
