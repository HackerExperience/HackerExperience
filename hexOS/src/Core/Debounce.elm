module Core.Debounce exposing (after, save)

import Debounce
import Task


after : Float -> (Debounce.Msg -> msg) -> Debounce.Config msg
after time msg =
    { strategy = Debounce.later time
    , transform = msg
    }


save : (v -> msg) -> v -> Cmd msg
save msg v =
    Task.perform msg (Task.succeed v)
