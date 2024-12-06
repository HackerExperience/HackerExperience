module Login exposing
    ( Model
    , Msg(..)
    , documentView
    , initialModel
    , update
    )

import API.Lobby as LobbyAPI
import API.Types
import API.Utils
import Effect exposing (Effect)
import UI exposing (UI, cl, col, row, text)
import UI.Button
import UI.Model.FormFields as FormFields exposing (TextField)
import UI.TextInput



-- Types


type Msg
    = SetEmail String
    | SetPassword String
    | OnFormSubmit
    | ProceedToBoot API.Types.InputToken
    | OnLoginResponse API.Types.LobbyLoginResult


type alias Model =
    { email : TextField
    , password : TextField
    }



-- Model


initialModel : Model
initialModel =
    { email = FormFields.textWithValue "renato@renato.com"
    , password = FormFields.textWithValue "renato"
    }



-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        -- Intercepted by `Main`
        ProceedToBoot _ ->
            ( model, Effect.none )

        SetEmail value ->
            ( { model | email = FormFields.setValue model.email value }, Effect.none )

        SetPassword value ->
            ( { model | password = FormFields.setValue model.password value }, Effect.none )

        OnFormSubmit ->
            let
                apiCtx =
                    API.Utils.buildContext Nothing API.Types.ServerLobby

                config =
                    LobbyAPI.loginConfig apiCtx model.email.value model.password.value
            in
            ( model, Effect.lobbyLogin OnLoginResponse config )

        OnLoginResponse (Ok { token }) ->
            ( model, Effect.msgToCmd <| ProceedToBoot (API.Utils.stringToToken token) )

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
