module Apps.LogViewer exposing (..)

import API.Game as GameAPI
import API.Types
import Apps.Manifest as App
import Effect exposing (Effect)
import Game
import Game.Model.Log exposing (Log, LogType(..))
import Game.Model.LogID as LogID exposing (LogID)
import Game.Model.NIP exposing (NIP)
import Game.Model.Server as Server
import Html.Attributes as HA
import Html.Events as HE
import OS.AppID exposing (AppID)
import OS.Bus
import OS.CtxMenu as CtxMenu
import OS.CtxMenu.Menus as CtxMenu
import UI exposing (UI, cl, col, div, row, text)
import UI.Icon
import WM



-- Types


type Msg
    = ToOS OS.Bus.Action
    | ToCtxMenu CtxMenu.Msg
    | SelectLog LogID
    | DeselectLog
    | OnDeleteLog Log
    | OnDeleteLogResponse API.Types.LogDeleteResult


type alias Model =
    { nip : NIP
    , selectedLog : Maybe LogID
    }



-- Model


filterLogs : Model -> Game.Model -> List Log
filterLogs model game =
    -- TODO: Currently this is not doing any filtering other than grabbing all logs in the server
    let
        server =
            Game.getServer game model.nip

        logs =
            Server.listLogs server
    in
    logs



-- Update


update : Game.Model -> Msg -> Model -> ( Model, Effect Msg )
update game msg model =
    case msg of
        SelectLog logId ->
            ( { model | selectedLog = Just logId }, Effect.none )

        DeselectLog ->
            ( { model | selectedLog = Nothing }, Effect.none )

        OnDeleteLog log ->
            let
                server =
                    Game.getServer game model.nip

                config =
                    GameAPI.logDeleteConfig game.apiCtx model.nip log.id server.tunnelId
            in
            ( model, Effect.logDelete OnDeleteLogResponse config )

        OnDeleteLogResponse (Ok res) ->
            let
                _ =
                    Debug.log "OK!" res
            in
            ( model, Effect.none )

        OnDeleteLogResponse (Err _) ->
            -- TODO
            ( model, Effect.none )

        ToOS _ ->
            -- Handled by OS
            ( model, Effect.none )

        ToCtxMenu _ ->
            -- Handled by OS
            ( model, Effect.none )



-- View


view : Model -> Game.Model -> CtxMenu.Model -> UI Msg
view model game ctxMenu =
    col
        [ cl "app-log-viewer"
        , UI.flexFill
        , HA.map ToCtxMenu (CtxMenu.event <| CtxMenu.LogViewer CtxMenu.LVRootMenu)
        ]
        [ vHeader
        , vBody model game
        , CtxMenu.view ctxMenu ToCtxMenu ctxMenuConfig model
        ]


vHeader : UI Msg
vHeader =
    row [ cl "a-log-header", UI.centerItems ] [ text "Header" ]


vBody : Model -> Game.Model -> UI Msg
vBody model game =
    col [ cl "a-log-body", UI.flexGrow, UI.flexFill ]
        (vLogList model game)


{-| TODO: Lazify
-}
vLogList : Model -> Game.Model -> List (UI Msg)
vLogList model game =
    let
        logs =
            filterLogs model game
    in
    List.map (\log -> vLogRow log) logs


vLogRow : Log -> UI Msg
vLogRow log =
    let
        time =
            "26/01 19:29:18"

        dateTime =
            row [ cl "a-log-row-date" ]
                [ text time
                ]

        separator =
            div [ cl "a-log-row-internal-separator" ] []

        editIcon =
            UI.Icon.msOutline "edit" Nothing
                |> UI.Icon.toUI

        deleteIcon =
            UI.Icon.msOutline "delete" Nothing
                |> UI.Icon.toUI

        editEntry =
            col [ cl "a-lr-action-entry" ]
                [ editIcon ]

        deleteEntry =
            col [ cl "a-lr-action-entry" ]
                [ deleteIcon ]

        actions =
            if not log.isDeleted then
                row [ cl "a-log-row-actions" ]
                    [ editEntry, deleteEntry ]

            else
                UI.emptyEl

        logText =
            row [ cl "a-log-row-text", UI.centerItems ]
                [ text log.rawText ]

        -- TODO: Move to dedicate function
        brokenBadgeIcon =
            UI.Icon.msOutline "warning" Nothing
                |> UI.Icon.withClass "a-lr-badge-broken"
                |> UI.Icon.toUI

        deletedBadgeIcon =
            UI.Icon.msOutline "cancel" Nothing
                |> UI.Icon.withClass "a-lr-badge-deleted"
                |> UI.Icon.toUI

        badges =
            case ( log.isDeleted, log.type_ ) of
                ( True, CustomLog ) ->
                    row [ cl "a-log-row-badges" ]
                        [ brokenBadgeIcon, deletedBadgeIcon ]

                ( True, _ ) ->
                    row [ cl "a-log-row-badges" ]
                        [ deletedBadgeIcon ]

                ( False, CustomLog ) ->
                    row [ cl "a-log-row-badges" ]
                        [ brokenBadgeIcon ]

                ( False, _ ) ->
                    UI.emptyEl
    in
    row
        [ cl "a-log-row"
        , if log.isDeleted then
            cl "a-log-row-deleted"

          else
            UI.emptyAttr
        , HE.onClick <| SelectLog log.id
        , HA.map ToCtxMenu (CtxMenu.event <| CtxMenu.LogViewer <| CtxMenu.LVEntryMenu log)
        ]
        [ dateTime
        , separator
        , badges
        , logText
        , actions
        ]



-- CtxMenu


ctxMenuConfig : CtxMenu.Menu -> Model -> Maybe (CtxMenu.Config Msg)
ctxMenuConfig menu _ =
    case menu of
        CtxMenu.LogViewer submenu ->
            case submenu of
                CtxMenu.LVRootMenu ->
                    Nothing

                CtxMenu.LVEntryMenu log ->
                    ctxMenuConfigEntry log

        _ ->
            Nothing


ctxMenuConfigEntry : Log -> Maybe (CtxMenu.Config Msg)
ctxMenuConfigEntry log =
    Just
        { entries = ctxMenuLogEntries log
        , mapper = ToCtxMenu
        }


ctxMenuLogEntries : Log -> List (CtxMenu.ConfigEntry Msg)
ctxMenuLogEntries log =
    if not log.isDeleted then
        [ CtxMenu.SimpleItem { label = "Edit", enabled = True, onClick = Nothing }
        , CtxMenu.SimpleItem { label = "Delete", enabled = True, onClick = Just <| OnDeleteLog log }
        ]

    else
        -- Note: Not sure that's the actual mechanic
        [ CtxMenu.SimpleItem { label = "Recover", enabled = False, onClick = Nothing } ]



-- OS.Dispatcher Callbacks


getWindowConfig : WM.WindowInfo -> WM.WindowConfig
getWindowConfig _ =
    { lenX = 800
    , lenY = 600
    , title = "Log Viewer"
    , childBehavior = Nothing
    , misc = Nothing
    }


willOpen : WM.WindowInfo -> OS.Bus.Action
willOpen _ =
    OS.Bus.OpenApp App.LogViewerApp Nothing


didOpen : WM.WindowInfo -> ( Model, Effect Msg )
didOpen { sessionId } =
    let
        -- TODO: Not worrying about this for now.
        nip =
            case sessionId of
                WM.LocalSessionID nip_ ->
                    nip_

                WM.RemoteSessionID nip_ ->
                    nip_
    in
    ( { nip = nip
      , selectedLog = Nothing
      }
    , Effect.none
    )



-- TODO: Implement didClose and, on close, close all singleton popups of one type but not the other


willClose : AppID -> Model -> WM.Window -> OS.Bus.Action
willClose appId _ _ =
    OS.Bus.CloseApp appId


willFocus : AppID -> WM.Window -> OS.Bus.Action
willFocus appId _ =
    OS.Bus.FocusApp appId



-- Children
-- TODO: Singleton logic can (and probably should) be delegated to the OS/WM


willOpenChild : Model -> App.Manifest -> WM.Window -> WM.WindowInfo -> OS.Bus.Action
willOpenChild _ child parentWindow _ =
    OS.Bus.OpenApp child <| Just ( App.DemoApp, parentWindow.appId )


didOpenChild :
    Model
    -> ( App.Manifest, AppID )
    -> WM.WindowInfo
    -> ( Model, Effect Msg, OS.Bus.Action )
didOpenChild model _ _ =
    ( model, Effect.none, OS.Bus.NoOp )


didCloseChild :
    Model
    -> ( App.Manifest, AppID )
    -> WM.Window
    -> ( Model, Effect Msg, OS.Bus.Action )
didCloseChild model _ _ =
    -- TODO: Make defaults for these
    ( model, Effect.none, OS.Bus.NoOp )
