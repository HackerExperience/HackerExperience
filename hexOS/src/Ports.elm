port module Ports exposing
    ( eventStart
    , eventSubscriber
    )


port eventStart : String -> Cmd msg


port eventSubscriber : (String -> msg) -> Sub msg
