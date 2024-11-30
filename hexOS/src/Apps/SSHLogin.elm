module Apps.SSHLogin exposing (..)

import Apps.Manifest as App
import Effect exposing (Effect)
import Game.Model as Game
import Html.Events as HE
import OS.AppID exposing (AppID)
import OS.Bus
import UI exposing (UI, cl, col, div, row, text)
import WM



-- Types


type Msg
    = ToOS OS.Bus.Action


type alias Model =
    { ip : Maybe String }



-- Model
-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ToOS _ ->
            ( model, Effect.none )



-- View


view : Model -> Game.Model -> UI Msg
view model game =
    row [] [ text "Hey" ]



-- OS.Dispatcher Callbacks


getWindowConfig : WM.WindowInfo -> WM.WindowConfig
getWindowConfig _ =
    { lenX = 400
    , lenY = 400
    , title = "Secure Shell (SSH) login"
    , childBehavior = Nothing
    , misc = Nothing
    }


willOpen : WM.WindowInfo -> OS.Bus.Action
willOpen _ =
    OS.Bus.OpenApp App.SSHLoginApp Nothing


didOpen : WM.WindowInfo -> ( Model, Effect Msg )
didOpen _ =
    ( { ip = Nothing
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
