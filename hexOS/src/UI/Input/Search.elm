module UI.Input.Search exposing (..)

import UI exposing (UI, cl, row)
import UI.Icon
import UI.TextInput


search : UI msg
search =
    row [ UI.flexGrow ]
        [ inputView ]



-- iconView : UI msg
-- iconView =
--     UI.Icon.iSearch "hint"
--         |> UI.Icon.toUI


inputView : UI msg
inputView =
    UI.Icon.iSearch Nothing
        |> UI.TextInput.fromIcon "asdfasdf"
        |> UI.TextInput.toUI
