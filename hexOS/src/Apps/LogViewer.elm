module Apps.LogViewer exposing (..)

import Apps.Manifest as App
import Effect exposing (Effect)
import Game.Model as Game
import Game.Model.LogID exposing (LogID)
import OS.AppID exposing (AppID)
import OS.Bus
import UI exposing (UI, text)
import WM



-- Types


type Msg
    = ToOS OS.Bus.Action


type alias Model =
    { selectedLog : Maybe LogID
    }



-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ToOS _ ->
            ( model, Effect.none )



-- View


view : Model -> Game.Model -> UI Msg
view model__ game__ =
    text "hey"



-- OS.Dispatcher Callbacks


getWindowConfig : WM.WindowInfo -> WM.WindowConfig
getWindowConfig _ =
    { lenX = 800
    , lenY = 600
    , title = "Log Viewer"
    , childBehavior = Nothing
    , misc = Nothing
    }


willOpen : WM.WindowInfo -> OS.Bus.Action
willOpen _ =
    OS.Bus.OpenApp App.LogViewerApp Nothing


didOpen : WM.WindowInfo -> ( Model, Effect Msg )
didOpen _ =
    ( { selectedLog = Nothing }
    , Effect.none
    )



-- TODO: Implement didClose and, on close, close all singleton popups of one type but not the other


willClose : AppID -> Model -> WM.Window -> OS.Bus.Action
willClose appId _ _ =
    OS.Bus.CloseApp appId


willFocus : AppID -> WM.Window -> OS.Bus.Action
willFocus appId _ =
    OS.Bus.FocusApp appId



-- Children
-- TODO: Singleton logic can (and probably should) be delegated to the OS/WM


willOpenChild : Model -> App.Manifest -> WM.Window -> WM.WindowInfo -> OS.Bus.Action
willOpenChild _ child parentWindow _ =
    OS.Bus.OpenApp child <| Just ( App.DemoApp, parentWindow.appId )


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
    -- TODO: Make defaults for these
    ( model, Effect.none, OS.Bus.NoOp )
