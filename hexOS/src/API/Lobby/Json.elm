module API.Lobby.Json exposing
    ( encodeGenericError, encodeGenericErrorResponse, encodeGenericUnauthorizedResponse, encodeUserLoginInput
    , encodeUserLoginOkResponse, encodeUserLoginOutput, encodeUserLoginRequest, encodeUserRegisterInput
    , encodeUserRegisterOkResponse, encodeUserRegisterOutput, encodeUserRegisterRequest
    , decodeGenericError, decodeGenericErrorResponse, decodeGenericUnauthorizedResponse, decodeUserLoginInput
    , decodeUserLoginOkResponse, decodeUserLoginOutput, decodeUserLoginRequest, decodeUserRegisterInput
    , decodeUserRegisterOkResponse, decodeUserRegisterOutput, decodeUserRegisterRequest
    )

{-|


## Encoders

@docs encodeGenericError, encodeGenericErrorResponse, encodeGenericUnauthorizedResponse, encodeUserLoginInput
@docs encodeUserLoginOkResponse, encodeUserLoginOutput, encodeUserLoginRequest, encodeUserRegisterInput
@docs encodeUserRegisterOkResponse, encodeUserRegisterOutput, encodeUserRegisterRequest


## Decoders

@docs decodeGenericError, decodeGenericErrorResponse, decodeGenericUnauthorizedResponse, decodeUserLoginInput
@docs decodeUserLoginOkResponse, decodeUserLoginOutput, decodeUserLoginRequest, decodeUserRegisterInput
@docs decodeUserRegisterOkResponse, decodeUserRegisterOutput, decodeUserRegisterRequest

-}

import API.Lobby.Types
import Json.Decode
import Json.Encode
import OpenApi.Common


decodeUserRegisterOutput : Json.Decode.Decoder API.Lobby.Types.UserRegisterOutput
decodeUserRegisterOutput =
    Json.Decode.succeed (\id -> { id = id })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "id"
                Json.Decode.string
            )


encodeUserRegisterOutput : API.Lobby.Types.UserRegisterOutput -> Json.Encode.Value
encodeUserRegisterOutput rec =
    Json.Encode.object [ ( "id", Json.Encode.string rec.id ) ]


decodeUserRegisterInput : Json.Decode.Decoder API.Lobby.Types.UserRegisterInput
decodeUserRegisterInput =
    Json.Decode.succeed
        (\email password username ->
            { email = email, password = password, username = username }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "email" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "password"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "username"
                Json.Decode.string
            )


encodeUserRegisterInput : API.Lobby.Types.UserRegisterInput -> Json.Encode.Value
encodeUserRegisterInput rec =
    Json.Encode.object
        [ ( "email", Json.Encode.string rec.email )
        , ( "password", Json.Encode.string rec.password )
        , ( "username", Json.Encode.string rec.username )
        ]


decodeUserLoginOutput : Json.Decode.Decoder API.Lobby.Types.UserLoginOutput
decodeUserLoginOutput =
    Json.Decode.succeed
        (\token -> { token = token })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "token"
                Json.Decode.string
            )


encodeUserLoginOutput : API.Lobby.Types.UserLoginOutput -> Json.Encode.Value
encodeUserLoginOutput rec =
    Json.Encode.object [ ( "token", Json.Encode.string rec.token ) ]


decodeUserLoginInput : Json.Decode.Decoder API.Lobby.Types.UserLoginInput
decodeUserLoginInput =
    Json.Decode.succeed
        (\email password -> { email = email, password = password })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "email" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "password"
                Json.Decode.string
            )


encodeUserLoginInput : API.Lobby.Types.UserLoginInput -> Json.Encode.Value
encodeUserLoginInput rec =
    Json.Encode.object
        [ ( "email", Json.Encode.string rec.email )
        , ( "password", Json.Encode.string rec.password )
        ]


decodeGenericError : Json.Decode.Decoder API.Lobby.Types.GenericError
decodeGenericError =
    Json.Decode.succeed
        (\error -> { error = error })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "error"
                Json.Decode.string
            )


encodeGenericError : API.Lobby.Types.GenericError -> Json.Encode.Value
encodeGenericError rec =
    Json.Encode.object [ ( "error", Json.Encode.string rec.error ) ]


decodeUserRegisterOkResponse : Json.Decode.Decoder API.Lobby.Types.UserRegisterOkResponse
decodeUserRegisterOkResponse =
    Json.Decode.succeed
        (\data -> { data = data })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "data"
                decodeUserRegisterOutput
            )


encodeUserRegisterOkResponse : API.Lobby.Types.UserRegisterOkResponse -> Json.Encode.Value
encodeUserRegisterOkResponse rec =
    Json.Encode.object [ ( "data", encodeUserRegisterOutput rec.data ) ]


decodeUserLoginOkResponse : Json.Decode.Decoder API.Lobby.Types.UserLoginOkResponse
decodeUserLoginOkResponse =
    Json.Decode.succeed
        (\data -> { data = data })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "data"
                decodeUserLoginOutput
            )


encodeUserLoginOkResponse : API.Lobby.Types.UserLoginOkResponse -> Json.Encode.Value
encodeUserLoginOkResponse rec =
    Json.Encode.object [ ( "data", encodeUserLoginOutput rec.data ) ]


decodeGenericUnauthorizedResponse : Json.Decode.Decoder API.Lobby.Types.GenericUnauthorizedResponse
decodeGenericUnauthorizedResponse =
    Json.Decode.succeed ()


encodeGenericUnauthorizedResponse : API.Lobby.Types.GenericUnauthorizedResponse -> Json.Encode.Value
encodeGenericUnauthorizedResponse rec =
    Json.Encode.null


decodeGenericErrorResponse : Json.Decode.Decoder API.Lobby.Types.GenericErrorResponse
decodeGenericErrorResponse =
    decodeGenericError


encodeGenericErrorResponse : API.Lobby.Types.GenericErrorResponse -> Json.Encode.Value
encodeGenericErrorResponse =
    encodeGenericError


decodeUserRegisterRequest : Json.Decode.Decoder API.Lobby.Types.UserRegisterRequest
decodeUserRegisterRequest =
    decodeUserRegisterInput


encodeUserRegisterRequest : API.Lobby.Types.UserRegisterRequest -> Json.Encode.Value
encodeUserRegisterRequest =
    encodeUserRegisterInput


decodeUserLoginRequest : Json.Decode.Decoder API.Lobby.Types.UserLoginRequest
decodeUserLoginRequest =
    decodeUserLoginInput


encodeUserLoginRequest : API.Lobby.Types.UserLoginRequest -> Json.Encode.Value
encodeUserLoginRequest =
    encodeUserLoginInput
