module HUD.Dock exposing
    ( Msg(..)
    , view
    )

import Apps.Manifest as App
import Dict
import OS.AppID exposing (AppID)
import OS.Bus
import State exposing (State)
import UI exposing (UI, cl, div, id, row, text)
import UI.Icon
import WM


type Msg
    = ToOS OS.Bus.Action
    | NoOp



-- View


view : State -> WM.Model -> UI Msg
view state wm =
    -- TODO: Lazify
    let
        appEntries =
            Dict.foldr (renderAppEntry state) [] wm.windows
    in
    row [ id "hud-dock" ]
        appEntries


renderAppEntry : State -> AppID -> WM.Window -> List (UI Msg) -> List (UI Msg)
renderAppEntry state _ window acc =
    if shouldRenderEntry state window then
        viewAppEntry window :: acc

    else
        acc


shouldRenderEntry : State -> WM.Window -> Bool
shouldRenderEntry state window =
    not window.isPopup && window.sessionID == state.currentSession && window.universe == state.currentUniverse


viewAppEntry : WM.Window -> UI Msg
viewAppEntry { appId, app } =
    let
        ( name, iconName ) =
            ( App.getName app, App.getIcon app )

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
    row
        [ cl "hud-d-entry-area"
        , UI.onClick <| ToOS <| OS.Bus.RequestFocusApp appId
        ]
        [ entryIconArea
        , div [ cl "hud-d-entry-icon-separator" ] []
        , entryNameArea
        ]
