port module Ports exposing (..)


port eventStart : String -> Cmd msg


port eventSubscriber : (String -> msg) -> Sub msg
