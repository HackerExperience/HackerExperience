module Game.Bus exposing (Action(..))

-- TODO: Maybe rename this to State.Bus?

import Game.Model.NIP exposing (NIP)
import Game.Universe exposing (Universe)


type Action
    = ActionNoOp
    | SwitchGateway Universe NIP
    | SwitchEndpoint Universe NIP
    | ToggleWMSession
