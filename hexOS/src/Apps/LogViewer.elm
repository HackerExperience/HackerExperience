module Apps.LogViewer exposing (..)

import Apps.Manifest as App
import Effect exposing (Effect)
import Game
import Game.Model.Log exposing (Log)
import Game.Model.LogID exposing (LogID)
import Html.Attributes as HA
import Html.Events as HE
import OS.AppID exposing (AppID)
import OS.Bus
import OS.CtxMenu as CtxMenu
import OS.CtxMenu.Menus as CtxMenu
import UI exposing (UI, cl, col, div, row, text)
import WM



-- Types


type Msg
    = ToOS OS.Bus.Action
    | ToCtxMenu CtxMenu.Msg
    | SelectLog LogID
    | DeselectLog


type alias Model =
    { selectedLog : Maybe LogID
    }



-- Model


filterLogs : Model -> Game.Model -> List Log
filterLogs _ _ =
    -- TODO: Figure out a way to handle ServerID (for gateways) and NIPs (for endpoints)
    -- TODO: Currently this is not doing any filtering other than grabbing all logs in the server
    -- let
    --     server =
    --         Game.getGateway game model.serverId
    -- in
    -- Server.listLogs server
    []



-- Update


update : Game.Model -> Msg -> Model -> ( Model, Effect Msg )
update _ msg model =
    case msg of
        SelectLog logId ->
            ( { model | selectedLog = Just logId }, Effect.none )

        DeselectLog ->
            ( { model | selectedLog = Nothing }, Effect.none )

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
        date =
            "26/01/2019"

        time =
            "19:29:18"

        vLogRowDateTime =
            col [ cl "a-log-row-date", UI.centerItems ]
                [ row [ UI.centerItems, UI.heightFill ] [ text date ]
                , row [ UI.centerItems, UI.heightFill ] [ text time ]
                ]

        vLogRowSeparator =
            div [ cl "a-log-row-internal-separator" ] []

        vLogRowText =
            row [ cl "a-log-row-text", UI.centerItems ] [ text log.rawText ]
    in
    row
        [ cl "a-log-row"
        , HE.onClick <| SelectLog log.id
        ]
        [ vLogRowDateTime
        , vLogRowSeparator
        , vLogRowText
        ]



-- CtxMenu


ctxMenuConfig : CtxMenu.Menu -> Model -> Maybe (CtxMenu.Config Msg)
ctxMenuConfig menu _ =
    case menu of
        CtxMenu.LogViewer submenu ->
            case submenu of
                CtxMenu.LVRootMenu ->
                    Just
                        { entries = [ CtxMenu.SimpleItem { label = "Log 1", enabled = True, onClick = Nothing } ]
                        , mapper = ToCtxMenu
                        }

                _ ->
                    Nothing

        _ ->
            Nothing



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
didOpen _ =
    ( { selectedLog = Nothing
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
