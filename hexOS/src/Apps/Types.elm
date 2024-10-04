-- TODO: Maybe move this to inside OS itself


module Apps.Types exposing (..)

import Apps.Demo as Demo
import Apps.LogViewer as LogViewer
import Apps.Popups.ConfirmationDialog as ConfirmationDialog
import Apps.Popups.DemoSingleton as DemoSingleton
import OS.AppID exposing (AppID)


type Msg
    = InvalidMsg
    | LogViewerMsg AppID LogViewer.Msg
    | DemoMsg AppID Demo.Msg
      -- Popups
    | PopupConfirmationDialogMsg AppID ConfirmationDialog.Msg
    | PopupDemoSingletonMsg AppID DemoSingleton.Msg


type Model
    = InvalidModel
    | LogViewerModel LogViewer.Model
    | DemoModel Demo.Model
      -- Popups
    | PopupConfirmationDialogModel ConfirmationDialog.Model
    | PopupDemoSingletonModel DemoSingleton.Model
