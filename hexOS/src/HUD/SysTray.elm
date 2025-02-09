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
    col [ id "hud-systray" ]
        -- TODO: If top/bottom are identical, just rename it to be the same class
        [ row [ cl "hud-st-top-area" ]
            [ viewHeatBar
            , viewTraceBar
            ]
        , row [ cl "hud-st-bottom-area" ]
            [ viewInstalledApps
            , viewClock
            ]
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

        -- , installedApp
        -- , installedApp
        -- , installedApp
        -- , installedApp
        -- , installedApp
        -- , installedApp
        -- , installedApp
        -- , installedApp
        ]


viewClock : UI Msg
viewClock =
    row [ cl "hud-st-clock-area" ]
        [ text "10:15 am" ]


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
