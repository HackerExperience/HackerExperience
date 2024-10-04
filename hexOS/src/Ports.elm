port module Ports exposing
    ( eventStart
    , eventSubscriber
    )

import Json.Decode as JD
import Json.Encode as JE


port eventStart : JD.Value -> Cmd msg


port eventSubscriber : (JE.Value -> msg) -> Sub msg
