-- TODO: Maybe move this to inside OS itself


module Apps.Types exposing (..)

import Apps.AppStore as AppStore
import Apps.Demo as Demo
import Apps.LogViewer as LogViewer
import Apps.LogViewer.LogEditPopup as LogEditPopup
import Apps.Popups.ConfirmationPrompt as ConfirmationPrompt
import Apps.Popups.ConfirmationPrompt.Types as ConfirmationPrompt
import Apps.Popups.DemoSingleton as DemoSingleton
import Apps.RemoteAccess as RemoteAccess
import OS.AppID exposing (AppID)


type Msg
    = InvalidMsg
    | AppStoreMsg AppID AppStore.Msg
    | LogViewerMsg AppID LogViewer.Msg
    | RemoteAccessMsg AppID RemoteAccess.Msg
    | DemoMsg AppID Demo.Msg
      -- Popups
    | PopupLogEditMsg AppID LogEditPopup.Msg
    | PopupConfirmationPromptMsg AppID ConfirmationPrompt.Msg
    | PopupDemoSingletonMsg AppID DemoSingleton.Msg


type Model
    = InvalidModel
    | AppStoreModel AppStore.Model
    | LogViewerModel LogViewer.Model
    | RemoteAccessModel RemoteAccess.Model
    | DemoModel Demo.Model
      -- Popups
    | PopupLogEditModel LogEditPopup.Model
    | PopupConfirmationPromptModel ConfirmationPrompt.Model
    | PopupDemoSingletonModel DemoSingleton.Model
