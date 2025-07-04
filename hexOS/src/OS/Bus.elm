module OS.Bus exposing (Action(..), ParentInfo)

import Apps.Input
import Apps.Manifest as App
import Game.Bus
import OS.AppID exposing (AppID)
import OS.CtxMenu as CtxMenu


type alias ParentInfo =
    ( App.Manifest, AppID )


type Action
    = NoOp
      -- App
    | RequestOpenApp App.Manifest (Maybe ParentInfo) Apps.Input.InitialInput
    | RequestCloseApp AppID
    | RequestCloseChildren AppID
    | RequestFocusApp AppID
    | OpenApp App.Manifest (Maybe ParentInfo) Apps.Input.InitialInput
    | CloseApp AppID
    | FocusApp AppID
    | FocusVibrateApp AppID
    | UnvibrateApp AppID
    | CollapseApp AppID
    | ToGame Game.Bus.Action
    | ToCtxMenu CtxMenu.Msg
