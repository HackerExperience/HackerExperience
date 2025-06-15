module Apps.Popups.ConfirmationPrompt.Types exposing (..)

import Apps.Manifest as App
import OS.AppID exposing (AppID)


type ActionOption
    = ActionConfirmCancel String String
    | ActionConfirmOnly String


type Action
    = Confirm
    | Cancel


type Msg
    = ToParent Action
