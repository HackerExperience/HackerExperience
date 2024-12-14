port module Ports exposing
    ( eventStart
    , eventSubscriber
    )

import Json.Encode as JE


port eventStart : JE.Value -> Cmd msg


port eventSubscriber : (JE.Value -> msg) -> Sub msg
