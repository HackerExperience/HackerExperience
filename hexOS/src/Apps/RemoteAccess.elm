module Apps.RemoteAccess exposing (..)

import API.Game as GameAPI
import API.Types
import Apps.Manifest as App
import Effect exposing (Effect)
import Game
import Game.Model.NIP as NIP
import OS.AppID exposing (AppID)
import OS.Bus
import Regex
import UI exposing (UI, col)
import UI.Button
import UI.Model.FormFields as FormFields exposing (TextField)
import UI.TextInput
import WM



-- Types


type Msg
    = ToOS OS.Bus.Action
    | SetIPAddress String
    | ValidateIPAddress
    | SetPassword String
    | ValidatePassword
    | OnFormSubmit
    | OnLoginResponse API.Types.ServerLoginResult


type alias Model =
    { ip : TextField
    , password : TextField
    }



-- Model


{-| All this IP validation logic should be in a different module, of course
-}
ipContainsInvalidCharactersRegex : Regex.Regex
ipContainsInvalidCharactersRegex =
    Maybe.withDefault Regex.never <|
        Regex.fromString "[^0-9.]"


ipContainsInvalidCharacters : String -> Bool
ipContainsInvalidCharacters ip =
    Regex.contains ipContainsInvalidCharactersRegex ip


ipValid : String -> Bool
ipValid _ =
    -- TODO
    True



-- Update


update : Game.Model -> Msg -> Model -> ( Model, Effect Msg )
update game msg model =
    case msg of
        ToOS _ ->
            ( model, Effect.none )

        SetIPAddress value ->
            if not (ipContainsInvalidCharacters value) then
                let
                    newIp =
                        FormFields.setValue model.ip value
                            |> FormFields.unsetError
                in
                ( { model | ip = newIp }, Effect.none )

            else
                ( model, Effect.none )

        ValidateIPAddress ->
            if ipValid model.ip.value then
                ( model, Effect.none )

            else
                ( { model | ip = FormFields.setError model.ip "Invalid IP" }, Effect.none )

        SetPassword value ->
            ( { model | password = FormFields.setValue model.password value }, Effect.none )

        ValidatePassword ->
            ( model, Effect.none )

        OnFormSubmit ->
            let
                gateway =
                    Game.getGateway game game.activeGateway

                targetNip =
                    NIP.new "0" model.ip.value

                config =
                    GameAPI.serverLoginConfig game.apiCtx gateway.nip targetNip Nothing
            in
            ( model, Effect.serverLogin OnLoginResponse config )

        OnLoginResponse (Ok _) ->
            ( model, Effect.none )

        OnLoginResponse (Err _) ->
            ( model, Effect.none )



-- View


view : Model -> Game.Model -> UI Msg
view model _ =
    col []
        [ UI.TextInput.new "IP" model.ip
            |> UI.TextInput.withOnChange SetIPAddress
            |> UI.TextInput.withOnBlur ValidateIPAddress
            |> UI.TextInput.toUI
        , UI.TextInput.new "Password" model.password
            |> UI.TextInput.withOnChange SetPassword
            |> UI.TextInput.withOnBlur ValidatePassword
            |> UI.TextInput.toUI
        , UI.Button.new (Just "Login")
            |> UI.Button.withOnClick OnFormSubmit
            |> UI.Button.toUI
        ]



-- OS.Dispatcher Callbacks


getWindowConfig : WM.WindowInfo -> WM.WindowConfig
getWindowConfig _ =
    { lenX = 400
    , lenY = 400
    , title = "Secure Shell login"
    , childBehavior = Nothing
    , misc = Nothing
    }


willOpen : WM.WindowInfo -> OS.Bus.Action
willOpen _ =
    OS.Bus.OpenApp App.RemoteAccessApp Nothing


didOpen : WM.WindowInfo -> ( Model, Effect Msg )
didOpen _ =
    ( { ip = FormFields.text
      , password = FormFields.text
      }
    , Effect.none
    )


willClose : AppID -> Model -> WM.Window -> OS.Bus.Action
willClose appId _ _ =
    OS.Bus.CloseApp appId


willFocus : AppID -> WM.Window -> OS.Bus.Action
willFocus appId _ =
    OS.Bus.FocusApp appId



-- Children


willOpenChild : Model -> App.Manifest -> WM.Window -> WM.WindowInfo -> OS.Bus.Action
willOpenChild _ _ _ _ =
    OS.Bus.NoOp


didOpenChild :
    Model
    -> ( App.Manifest, AppID )
    -> WM.WindowInfo
    -> ( Model, Effect Msg, OS.Bus.Action )
didOpenChild model _ _ =
    ( model, Effect.none, OS.Bus.NoOp )


didCloseChild :
    Model
    -> ( App.Manifest, AppID )
    -> WM.Window
    -> ( Model, Effect Msg, OS.Bus.Action )
didCloseChild model _ _ =
    ( model, Effect.none, OS.Bus.NoOp )
