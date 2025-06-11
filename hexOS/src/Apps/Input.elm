module Apps.Input exposing (..)

import Game.Model.Log exposing (Log)
import Game.Model.NIP exposing (NIP)


type InitialInput
    = EmptyInput
    | PopupLogEditInput NIP Log
