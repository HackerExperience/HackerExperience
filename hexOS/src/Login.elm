module Login exposing (..)

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
    | OnLoginOk String
    | ProceedToBoot String


type alias Model =
    { email : String
    , password : String
    }



-- Model


initialModel : Model
initialModel =
    { email = "", password = "" }



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetEmail value ->
            ( { model | email = value }, Cmd.none )

        SetPassword value ->
            ( { model | password = value }, Cmd.none )

        OnFormSubmit ->
            ( model, Utils.msgToCmd (OnLoginOk "token") )

        OnLoginOk token ->
            ( model, Utils.msgToCmd (ProceedToBoot token) )

        ProceedToBoot _ ->
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
