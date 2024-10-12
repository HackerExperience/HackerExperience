module Game.Bus exposing (Action(..))

import Game.Universe exposing (Universe)


type Action
    = ActionNoOp
    | SwitchGateway Universe Int
