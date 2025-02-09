module HUD.Dock exposing
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
    row [ id "hud-dock" ]
        [ viewAppEntry "Log Viewer" "list_alt"
        , viewAppEntry "File Explorer" "folder"
        ]


viewAppEntry : String -> String -> UI Msg
viewAppEntry name iconName =
    let
        icon =
            UI.Icon.msOutline iconName Nothing
                |> UI.Icon.toUI

        entryIconArea =
            row [ cl "hud-d-entry-icon-area" ]
                [ icon ]

        entryNameArea =
            row [ cl "hud-d-entry-name-area" ]
                [ text name ]
    in
    row [ cl "hud-d-entry-area" ]
        [ entryIconArea
        , div [ cl "hud-d-entry-icon-separator" ] []
        , entryNameArea
        ]
