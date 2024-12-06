-- TODO: Maybe move this to inside OS itself


module Apps.Types exposing (..)

import Apps.Demo as Demo
import Apps.LogViewer as LogViewer
import Apps.Popups.ConfirmationDialog as ConfirmationDialog
import Apps.Popups.DemoSingleton as DemoSingleton
import Apps.RemoteAccess as RemoteAccess
import OS.AppID exposing (AppID)


type Msg
    = InvalidMsg
    | LogViewerMsg AppID LogViewer.Msg
    | RemoteAccessMsg AppID RemoteAccess.Msg
    | DemoMsg AppID Demo.Msg
      -- Popups
    | PopupConfirmationDialogMsg AppID ConfirmationDialog.Msg
    | PopupDemoSingletonMsg AppID DemoSingleton.Msg


type Model
    = InvalidModel
    | LogViewerModel LogViewer.Model
    | RemoteAccessModel RemoteAccess.Model
    | DemoModel Demo.Model
      -- Popups
    | PopupConfirmationDialogModel ConfirmationDialog.Model
    | PopupDemoSingletonModel DemoSingleton.Model
