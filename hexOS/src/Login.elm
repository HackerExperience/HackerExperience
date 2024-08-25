module Login exposing (..)

import API.Lobby as LobbyAPI
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
    | OnLoginResponse (Result (LobbyAPI.Error LobbyAPI.LoginError) LobbyAPI.LoginResponse)


type alias Model =
    { email : String
    , password : String
    }



-- Model


initialModel : Model
initialModel =
    { email = "renato@renato.com", password = "renato" }



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Intercepted by `Main`
        ProceedToBoot _ ->
            ( model, Cmd.none )

        SetEmail value ->
            ( { model | email = value }, Cmd.none )

        SetPassword value ->
            ( { model | password = value }, Cmd.none )

        OnFormSubmit ->
            let
                task =
                    LobbyAPI.login model.email model.password
            in
            ( model, Task.attempt OnLoginResponse task )

        OnLoginResponse (Ok { token }) ->
            ( model, Utils.msgToCmd <| ProceedToBoot token )

        OnLoginResponse (Err (LobbyAPI.AppError _)) ->
            ( model, Cmd.none )

        OnLoginResponse (Err LobbyAPI.InternalError) ->
            ( model, Cmd.none )



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
