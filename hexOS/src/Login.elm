module Login exposing (..)

import API.Lobby as LobbyAPI
import API.Types
import Effect exposing (Effect)
import Task
import UI exposing (UI, cl, col, id, row, style, text)
import UI.Button
import UI.Icon
import UI.TextInput
import Utils



-- Types


type Msg
    = SetEmail String
    | SetPassword String
    | OnFormSubmit
    | ProceedToBoot String
    | OnLoginResponse API.Types.LobbyLoginResult


type alias Model =
    { email : String
    , password : String
    }



-- Model


initialModel : Model
initialModel =
    { email = "renato@renato.com", password = "renato" }



-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        -- Intercepted by `Main`
        ProceedToBoot _ ->
            ( model, Effect.none )

        SetEmail value ->
            ( { model | email = value }, Effect.none )

        SetPassword value ->
            ( { model | password = value }, Effect.none )

        OnFormSubmit ->
            let
                config =
                    LobbyAPI.loginConfig model.email model.password
            in
            ( model, Effect.lobbyLogin OnLoginResponse config )

        OnLoginResponse (Ok { token }) ->
            ( model, Effect.msgToCmd <| ProceedToBoot token )

        OnLoginResponse (Err (API.Types.AppError _)) ->
            ( model, Effect.none )

        OnLoginResponse (Err API.Types.InternalError) ->
            ( model, Effect.none )



-- View


documentView : Model -> UI.Document Msg
documentView model =
    { title = "Hacker Experience - Login", body = view model }


view : Model -> List (UI Msg)
view model =
    [ col [ cl "p-login-root" ]
        [ row [] [ text "Login header" ]
        , loginBox model

        -- , row []
        --     [ UI.link []
        --         [ text "Or Register instead!" ]
        --         (Route.toUrl <| Public Register)
        --     ]
        ]
    ]


loginBox : Model -> UI Msg
loginBox model =
    col []
        [ UI.TextInput.new "Email" model.email
            |> UI.TextInput.withOnChange SetEmail
            |> UI.TextInput.toUI
        , UI.TextInput.new "Password" model.password
            |> UI.TextInput.withPasswordType
            |> UI.TextInput.withOnChange SetPassword
            |> UI.TextInput.toUI
        , UI.Button.new (Just "Login")
            |> UI.Button.withOnClick OnFormSubmit
            |> UI.Button.toUI
        ]
