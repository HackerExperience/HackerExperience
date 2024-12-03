module Game.Msg exposing (Msg(..))

import Event exposing (Event)
import Game.Bus exposing (Action)


type Msg
    = NoOp
    | PerformAction Action
    | OnEventReceived Event
