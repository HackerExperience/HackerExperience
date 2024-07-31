module API.Lobby.Json exposing
    ( encodeEmptyOkResponse, encodeGenericError, encodeGenericErrorModel, encodeLoginOkResponse, encodeLoginUser
    , encodeLoginUserRequest, encodeNewUser, encodeNewUserRequest, encodeUnauthorized, encodeUser
    , encodeUserLoginResponse
    , decodeEmptyOkResponse, decodeGenericError, decodeGenericErrorModel, decodeLoginOkResponse, decodeLoginUser
    , decodeLoginUserRequest, decodeNewUser, decodeNewUserRequest, decodeUnauthorized, decodeUser
    , decodeUserLoginResponse
    )

{-|


## Encoders

@docs encodeEmptyOkResponse, encodeGenericError, encodeGenericErrorModel, encodeLoginOkResponse, encodeLoginUser
@docs encodeLoginUserRequest, encodeNewUser, encodeNewUserRequest, encodeUnauthorized, encodeUser
@docs encodeUserLoginResponse


## Decoders

@docs decodeEmptyOkResponse, decodeGenericError, decodeGenericErrorModel, decodeLoginOkResponse, decodeLoginUser
@docs decodeLoginUserRequest, decodeNewUser, decodeNewUserRequest, decodeUnauthorized, decodeUser
@docs decodeUserLoginResponse

-}

import API.Lobby.Types
import Json.Decode
import Json.Encode
import OpenApi.Common


decodeUserLoginResponse : Json.Decode.Decoder API.Lobby.Types.UserLoginResponse
decodeUserLoginResponse =
    Json.Decode.succeed
        (\token -> { token = token })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "token"
                Json.Decode.string
            )


encodeUserLoginResponse : API.Lobby.Types.UserLoginResponse -> Json.Encode.Value
encodeUserLoginResponse rec =
    Json.Encode.object [ ( "token", Json.Encode.string rec.token ) ]


decodeUser : Json.Decode.Decoder API.Lobby.Types.User
decodeUser =
    Json.Decode.succeed
        (\bio email image token username ->
            { bio = bio
            , email = email
            , image = image
            , token = token
            , username = username
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (OpenApi.Common.decodeOptionalField
                "bio"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "email" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "image"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "token"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "username"
                Json.Decode.string
            )


encodeUser : API.Lobby.Types.User -> Json.Encode.Value
encodeUser rec =
    Json.Encode.object
        (List.filterMap
            Basics.identity
            [ Maybe.map
                (\mapUnpack -> ( "bio", Json.Encode.string mapUnpack ))
                rec.bio
            , Just ( "email", Json.Encode.string rec.email )
            , Just ( "image", Json.Encode.string rec.image )
            , Just ( "token", Json.Encode.string rec.token )
            , Just ( "username", Json.Encode.string rec.username )
            ]
        )


decodeNewUser : Json.Decode.Decoder API.Lobby.Types.NewUser
decodeNewUser =
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


encodeNewUser : API.Lobby.Types.NewUser -> Json.Encode.Value
encodeNewUser rec =
    Json.Encode.object
        [ ( "email", Json.Encode.string rec.email )
        , ( "password", Json.Encode.string rec.password )
        , ( "username", Json.Encode.string rec.username )
        ]


decodeLoginUser : Json.Decode.Decoder API.Lobby.Types.LoginUser
decodeLoginUser =
    Json.Decode.succeed
        (\email password -> { email = email, password = password })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "email" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "password"
                Json.Decode.string
            )


encodeLoginUser : API.Lobby.Types.LoginUser -> Json.Encode.Value
encodeLoginUser rec =
    Json.Encode.object
        [ ( "email", Json.Encode.string rec.email )
        , ( "password", Json.Encode.string rec.password )
        ]


decodeGenericErrorModel : Json.Decode.Decoder API.Lobby.Types.GenericErrorModel
decodeGenericErrorModel =
    Json.Decode.succeed
        (\error -> { error = error })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "error"
                Json.Decode.string
            )


encodeGenericErrorModel : API.Lobby.Types.GenericErrorModel -> Json.Encode.Value
encodeGenericErrorModel rec =
    Json.Encode.object [ ( "error", Json.Encode.string rec.error ) ]


decodeUnauthorized : Json.Decode.Decoder API.Lobby.Types.Unauthorized
decodeUnauthorized =
    Json.Decode.succeed ()


encodeUnauthorized : API.Lobby.Types.Unauthorized -> Json.Encode.Value
encodeUnauthorized rec =
    Json.Encode.null


decodeLoginOkResponse : Json.Decode.Decoder API.Lobby.Types.LoginOkResponse
decodeLoginOkResponse =
    Json.Decode.succeed
        (\data -> { data = data })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "data"
                decodeUserLoginResponse
            )


encodeLoginOkResponse : API.Lobby.Types.LoginOkResponse -> Json.Encode.Value
encodeLoginOkResponse rec =
    Json.Encode.object [ ( "data", encodeUserLoginResponse rec.data ) ]


decodeGenericError : Json.Decode.Decoder API.Lobby.Types.GenericError
decodeGenericError =
    decodeGenericErrorModel


encodeGenericError : API.Lobby.Types.GenericError -> Json.Encode.Value
encodeGenericError =
    encodeGenericErrorModel


decodeEmptyOkResponse : Json.Decode.Decoder API.Lobby.Types.EmptyOkResponse
decodeEmptyOkResponse =
    Json.Decode.succeed ()


encodeEmptyOkResponse : API.Lobby.Types.EmptyOkResponse -> Json.Encode.Value
encodeEmptyOkResponse rec =
    Json.Encode.null


decodeNewUserRequest : Json.Decode.Decoder API.Lobby.Types.NewUserRequest
decodeNewUserRequest =
    Json.Decode.succeed
        (\user -> { user = user })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "user"
                decodeNewUser
            )


encodeNewUserRequest : API.Lobby.Types.NewUserRequest -> Json.Encode.Value
encodeNewUserRequest rec =
    Json.Encode.object [ ( "user", encodeNewUser rec.user ) ]


decodeLoginUserRequest : Json.Decode.Decoder API.Lobby.Types.LoginUserRequest
decodeLoginUserRequest =
    decodeLoginUser


encodeLoginUserRequest : API.Lobby.Types.LoginUserRequest -> Json.Encode.Value
encodeLoginUserRequest =
    encodeLoginUser
