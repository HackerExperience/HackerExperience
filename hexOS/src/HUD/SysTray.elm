module HUD.SysTray exposing
    ( Msg(..)
    , view
    )

import Html as H exposing (Html)
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
view state =
    row [ id "hud-systray" ]
        [ col [ cl "hud-st-left-area" ]
            [ viewTraceBar
            , viewInstalledApps
            ]
        , viewClock
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

        -- , row [] [ text "Jan 24th" ]
        ]


viewClock2 : UI Msg
viewClock2 =
    row [ cl "hud-st-clock-area orbitron-400" ]
        [ text "10:15 AM" ]


viewHeatBar : UI Msg
viewHeatBar =
    let
        noHeatIcon =
            UI.Icon.msOutline "ac_unit" Nothing
                |> UI.Icon.toUI

        noHeatView =
            row [ cl "hud-st-heat-noheat" ]
                [ noHeatIcon ]
    in
    row [ cl "hud-st-heat-area" ]
        [ noHeatView ]


viewTraceBar : UI Msg
viewTraceBar =
    let
        noTraceIcon =
            UI.Icon.msOutline "block" Nothing
                |> UI.Icon.toUI

        noTraceView =
            row [ cl "hud-st-trace-notrace" ]
                [ noTraceIcon ]
    in
    row [ cl "hud-st-trace-area" ]
        [ noTraceView ]
