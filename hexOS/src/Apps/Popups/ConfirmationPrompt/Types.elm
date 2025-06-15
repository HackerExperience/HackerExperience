module Apps.Popups.ConfirmationPrompt.Types exposing (..)


type ActionOption
    = ActionConfirmCancel String String
    | ActionConfirmOnly String


type Action
    = Confirm
    | Cancel


type Msg
    = ToParent Action
