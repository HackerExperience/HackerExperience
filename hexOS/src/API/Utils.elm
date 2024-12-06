module API.Utils exposing
    ( PrivateErrType(..)
    , buildContext
    , dataMapper
    , extractBody
    , extractBodyAndParams
    , extractBodyAndParamsNH
    , extractBodyNH
    , mapError
    , mapResponse
    , stringToToken
    , tokenToString
    )

import API.Types
    exposing
        ( APIServer(..)
        , Error
        , InputConfig
        , InputContext
        , InputToken(..)
        , ServerURL(..)
        )
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



-- Utils > Extract input


extractBody :
    InputConfig { body : b }
    -> { server : String, body : b, authorization : { authorization : String } }
extractBody config =
    { server = serverUrlToString config.server
    , body = config.input.body
    , authorization = { authorization = tokenToString config.authToken }
    }


{-| "No Header" variant
-}
extractBodyNH :
    InputConfig { body : b }
    -> { server : String, body : b }
extractBodyNH config =
    { server = serverUrlToString config.server, body = config.input.body }


extractBodyAndParams :
    InputConfig { body : b, params : p }
    -> { server : String, body : b, params : p, authorization : { authorization : String } }
extractBodyAndParams config =
    { server = serverUrlToString config.server
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
    { server = serverUrlToString config.server
    , body = config.input.body
    , params = config.input.params
    }



-- Utils > Context


buildContext : Maybe InputToken -> APIServer -> InputContext
buildContext maybeToken apiServer =
    let
        inputToken =
            case maybeToken of
                Just token ->
                    token

                Nothing ->
                    NoToken
    in
    { server = getServerUrl apiServer
    , token = inputToken
    }



-- Utils > Server


getServerUrl : APIServer -> ServerURL
getServerUrl server =
    case server of
        ServerLobby ->
            ServerURL "http://localhost:4000"

        ServerGameSP ->
            ServerURL "http://localhost:4001"

        ServerGameMP ->
            ServerURL "http://localhost:4002"


serverUrlToString : ServerURL -> String
serverUrlToString (ServerURL rawServerUrl) =
    rawServerUrl



-- Utils > Misc


stringToToken : String -> InputToken
stringToToken rawToken =
    InputToken rawToken


tokenToString : InputToken -> String
tokenToString inputToken =
    case inputToken of
        InputToken token ->
            token

        NoToken ->
            ""
