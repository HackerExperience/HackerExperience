module Apps.Popups.DemoSingleton exposing (..)

import Apps.Input as App
import Apps.Manifest as App
import Effect exposing (Effect)
import OS.AppID exposing (AppID)
import OS.Bus
import UI exposing (UI, text)
import WM


type Action
    = Confirm
    | Cancel


type Msg
    = ToApp AppID App.Manifest Action


type alias Model =
    {}


view : Model -> UI Msg
view _ =
    text "oi"



-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ToApp _ _ _ ->
            -- Here we can return OS error msg
            ( model, Effect.none )



-- OS.Dispatcher callbacks


getWindowConfig : WM.WindowInfo -> WM.WindowConfig
getWindowConfig _ =
    { lenX = 300
    , lenY = 200
    , title = "Demo Singleton Popup"
    , childBehavior = Nothing
    , misc = Nothing
    }


willOpen : WM.WindowInfo -> App.InitialInput -> OS.Bus.Action
willOpen window input =
    OS.Bus.OpenApp App.PopupDemoSingleton window.parent input


didOpen : WM.WindowInfo -> App.InitialInput -> ( Model, Effect Msg )
didOpen _ _ =
    ( {}, Effect.none )


willClose : AppID -> Model -> WM.Window -> OS.Bus.Action
willClose appId _ _ =
    OS.Bus.CloseApp appId


willFocus : AppID -> WM.Window -> OS.Bus.Action
willFocus appId _ =
    OS.Bus.FocusApp appId
