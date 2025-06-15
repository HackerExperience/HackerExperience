module Apps.Input exposing (..)

import Apps.Popups.ConfirmationPrompt.Types as ConfirmationDialog
import Game.Model.Log exposing (Log)
import Game.Model.NIP exposing (NIP)
import UI exposing (UI)


type InitialInput
    = EmptyInput
    | PopupLogEditInput NIP Log
    | PopupConfirmationDialogInput ( UI ConfirmationDialog.Msg, ConfirmationDialog.ActionOption )
