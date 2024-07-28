module OS.Bus exposing (..)

import Apps.Manifest as App
import OS.AppID exposing (AppID)


type alias ParentInfo =
    ( App.Manifest, AppID )


type Action
    = NoOp
      -- App
    | RequestOpenApp App.Manifest (Maybe ParentInfo)
    | RequestCloseApp AppID
    | RequestCloseChildren AppID
    | RequestFocusApp AppID
    | OpenApp App.Manifest (Maybe ParentInfo)
    | CloseApp AppID
    | FocusApp AppID
    | FocusVibrateApp AppID
    | UnvibrateApp AppID
