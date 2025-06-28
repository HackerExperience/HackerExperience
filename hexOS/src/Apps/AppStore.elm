module Apps.AppStore exposing (..)

import API.Game as GameAPI
import API.Types
import Apps.Input as App
import Apps.Manifest as App
import Dict exposing (Dict)
import Effect exposing (Effect)
import Game
import Game.Bus as Game
import Game.Model.Log as Log exposing (Log, LogType(..))
import Game.Model.LogID as LogID exposing (LogID, RawLogID)
import Game.Model.NIP exposing (NIP)
import Game.Model.ProcessOperation as Operation
import Game.Model.Server as Server
import Html.Attributes as HA
import Maybe.Extra as Maybe
import OS.AppID exposing (AppID)
import OS.Bus
import OS.CtxMenu as CtxMenu
import OS.CtxMenu.Menus as CtxMenu
import UI exposing (UI, cl, clIf, col, div, row, text)
import UI.Icon
import WM


type Msg
    = ToOS OS.Bus.Action
    | ToCtxMenu CtxMenu.Msg
    | Foo


type alias Model =
    { appId : AppID
    }



-- Model
-- Update


update : Game.Model -> Msg -> Model -> ( Model, Effect Msg )
update game msg model =
    ( model, Effect.none )



-- View


view : Model -> Game.Model -> CtxMenu.Model -> UI Msg
view model game ctxMenu =
    col
        [ cl "app-appstore" ]
        [ text "AppStore" ]



-- OS.Dispatcher Callbacks


getWindowConfig : WM.WindowInfo -> WM.WindowConfig
getWindowConfig _ =
    { lenX = 800
    , lenY = 600
    , title = "AppStore"
    , childBehavior = Nothing
    , misc = Nothing
    }


willOpen : WM.WindowInfo -> App.InitialInput -> OS.Bus.Action
willOpen _ input =
    OS.Bus.OpenApp App.AppStoreApp Nothing input


didOpen : WM.WindowInfo -> App.InitialInput -> ( Model, Effect Msg )
didOpen { appId } _ =
    ( { appId = appId }, Effect.none )



-- TODO: Implement didClose and, on close, close all singleton popups of one type but not the other


willClose : AppID -> Model -> WM.Window -> OS.Bus.Action
willClose appId _ _ =
    OS.Bus.CloseApp appId


willFocus : AppID -> WM.Window -> OS.Bus.Action
willFocus appId _ =
    OS.Bus.FocusApp appId



-- Children


willOpenChild :
    Model
    -> App.Manifest
    -> WM.Window
    -> WM.WindowInfo
    -> App.InitialInput
    -> OS.Bus.Action
willOpenChild _ child parentWindow _ input =
    OS.Bus.OpenApp child (Just ( App.LogViewerApp, parentWindow.appId )) input


didOpenChild :
    Model
    -> ( App.Manifest, AppID )
    -> WM.WindowInfo
    -> App.InitialInput
    -> ( Model, Effect Msg, OS.Bus.Action )
didOpenChild model _ _ _ =
    ( model, Effect.none, OS.Bus.NoOp )


didCloseChild :
    Model
    -> ( App.Manifest, AppID )
    -> WM.Window
    -> ( Model, Effect Msg, OS.Bus.Action )
didCloseChild model _ _ =
    -- TODO: Make defaults for these
    ( model, Effect.none, OS.Bus.NoOp )
