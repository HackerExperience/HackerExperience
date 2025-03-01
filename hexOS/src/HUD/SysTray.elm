module HUD.SysTray exposing
    ( Msg(..)
    , view
    )

import Html.Attributes as HA
import OS.Bus
import State exposing (State)
import UI exposing (UI, cl, col, div, id, row, text)
import UI.Icon


type Msg
    = ToOS OS.Bus.Action
    | NoOP



-- View


view : State -> UI Msg
view _ =
    row [ id "hud-systray" ]
        [ col [ cl "hud-st-left-area" ]
            [ viewTrayIcons
            , viewInstalledApps
            ]
        , viewClock
        , viewBuildVersion
        ]


viewInstalledApps : UI Msg
viewInstalledApps =
    let
        appIcon =
            UI.Icon.msOutline "folder" Nothing
                |> UI.Icon.toUI

        installedApp =
            row [ cl "hud-st-apps-entry-area" ]
                [ appIcon ]
    in
    row [ cl "hud-st-apps-area" ]
        [ div [] []
        , installedApp
        , installedApp
        ]


viewClock : UI Msg
viewClock =
    col [ cl "hud-st-clock-area orbitron-400" ]
        [ row [] [ text "10:15 AM " ]
        ]


viewTrayIcons : UI Msg
viewTrayIcons =
    let
        notificationIcon =
            UI.Icon.msOutline "notifications" Nothing
                |> UI.Icon.toUI

        settingsIcon =
            UI.Icon.msOutline "settings" Nothing
                |> UI.Icon.toUI

        trayEntry =
            \icon ->
                row [ cl "hud-st-tray-entry-area" ]
                    [ icon ]
    in
    row [ cl "hud-st-tray-area" ]
        [ trayEntry settingsIcon
        , trayEntry notificationIcon
        ]


viewBuildVersion : UI Msg
viewBuildVersion =
    row
        [ id "hud-build-version-area"
        , HA.alt "Foo"
        ]
        -- Currently just a placeholder
        [ text "v04.293.33" ]
