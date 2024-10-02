module Utils exposing (..)

import Process
import Task


msgToCmd : msg -> Cmd msg
msgToCmd msg =
    Task.succeed
        msg
        |> Task.perform identity


msgToCmdWithDelay : Float -> msg -> Cmd msg
msgToCmdWithDelay delay msg =
    Process.sleep delay
        |> Task.perform (always msg)
