module TestHelpers.Game exposing (..)

import Game exposing (State)
import Game.Universe as Universe exposing (Universe(..))
import TestHelpers.Mocks.Events as Mocks


state : State
state =
    let
        index =
            Mocks.indexRequested

        spModel =
            Universe.init index
    in
    Game.init Singleplayer spModel spModel
        |> Tuple.first
