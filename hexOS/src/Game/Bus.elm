module Game.Bus exposing (Action(..))

-- TODO: Maybe rename this to State.Bus?

import Game.Model.NIP exposing (NIP)
import Game.Model.ProcessOperation as ProcessOperation
import Game.Model.ServerID exposing (ServerID)
import Game.Universe exposing (Universe)


type Action
    = ActionNoOp
    | SwitchGateway Universe ServerID NIP
    | SwitchEndpoint Universe NIP
    | ToggleWMSession
    | ProcessOperation NIP ProcessOperation.Operation
