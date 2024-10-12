module Game.Msg exposing (Msg(..))

import Game.Bus exposing (Action)


type Msg
    = NoOp
    | PerformAction Action
