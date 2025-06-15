module Apps.Input exposing (..)

import Apps.Popups.ConfirmationPrompt.Types as ConfirmationPrompt
import Game.Model.Log exposing (Log)
import Game.Model.NIP exposing (NIP)
import UI exposing (UI)


type InitialInput
    = EmptyInput
    | PopupLogEditInput NIP Log
    | PopupConfirmationPromptInput ( UI ConfirmationPrompt.Msg, ConfirmationPrompt.ActionOption )
