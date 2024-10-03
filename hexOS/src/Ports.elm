port module Ports exposing
    ( eventStart
    , eventSubscriber
    )


import Json.Encode as JE
import Json.Decode as JD


port eventStart : JD.Value -> Cmd msg


port eventSubscriber : (JE.Value -> msg) -> Sub msg
