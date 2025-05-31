module Apps.LogViewer.LogEditPopup exposing (..)

import Apps.Input as App
import Apps.Manifest as App
import Effect exposing (Effect)
import Game
import Game.Model.Log as Log exposing (Log)
import OS.AppID exposing (AppID)
import OS.Bus
import UI exposing (UI, cl, row, text)
import UI.Button
import UI.Icon
import WM


type Msg
    = ToApp AppID App.Manifest OS.Bus.Action


type alias Model =
    { log : Log }



-- View


view : Model -> UI Msg
view model =
    text "oi"



-- Update


update : Game.Model -> Msg -> Model -> ( Model, Effect Msg )
update _ msg model =
    case msg of
        ToApp _ _ _ ->
            -- Here we can return OS error msg
            ( model, Effect.none )



-- OS.Dispatcher callbacks


getWindowConfig : WM.WindowInfo -> WM.WindowConfig
getWindowConfig _ =
    { lenX = 500
    , lenY = 500
    , title = "Log Edit"
    , childBehavior = Nothing
    , misc = Nothing
    }


willOpen : WM.WindowInfo -> App.InitialInput -> OS.Bus.Action
willOpen window input =
    OS.Bus.OpenApp App.PopupLogEdit window.parent input


didOpen : WM.WindowInfo -> App.InitialInput -> ( Model, Effect Msg )
didOpen _ input =
    -- TODO: Receive entire Log as input
    let
        log =
            case input of
                App.PopupLogEditInput logId ->
                    logId

                _ ->
                    Log.invalidLog
    in
    ( { log = log }, Effect.none )


willClose : AppID -> Model -> WM.Window -> OS.Bus.Action
willClose appId _ _ =
    OS.Bus.CloseApp appId


willFocus : AppID -> WM.Window -> OS.Bus.Action
willFocus appId _ =
    OS.Bus.FocusApp appId
