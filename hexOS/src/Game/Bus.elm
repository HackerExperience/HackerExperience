module Game.Bus exposing (Action(..))

import Game.Model.NIP exposing (NIP)
import Game.Model.ServerID exposing (ServerID)
import Game.Universe exposing (Universe)


type Action
    = ActionNoOp
    | SwitchGateway Universe ServerID
    | SwitchEndpoint Universe NIP
    | ToggleWMSession
