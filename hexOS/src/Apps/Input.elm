module Apps.Input exposing (..)

import Game.Model.Log exposing (Log)


type InitialInput
    = EmptyInput
    | PopupLogEditInput Log
