module HUD.Launcher exposing
    ( Msg(..)
    , view
    )

import OS.Bus
import UI exposing (UI, cl, col, div, id, row, text)
import UI.Icon
import WM


type Msg
    = ToOS OS.Bus.Action
    | NoOP



-- View


view : WM.Model -> UI Msg
view wm =
    row [ id "hud-launcher" ]
        [ viewLauncher ]


viewLauncher : UI Msg
viewLauncher =
    let
        icon =
            UI.Icon.msOutline "apps" Nothing
                |> UI.Icon.toUI

        iconArea =
            row [ cl "hud-l-launcher-icon-area" ]
                [ icon ]
    in
    row [ cl "hud-l-launcher-area" ]
        [ iconArea ]
