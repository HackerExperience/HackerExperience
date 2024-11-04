module Apps.LogViewer exposing (..)

import Apps.Manifest as App
import Effect exposing (Effect)
import Game.Model as Game
import Game.Model.Log exposing (Log)
import Game.Model.LogID exposing (LogID)
import Game.Model.Server as Server
import Game.Model.ServerID exposing (ServerID)
import Html.Events as HE
import OS.AppID exposing (AppID)
import OS.Bus
import UI exposing (UI, cl, col, div, row, text)
import WM



-- Types


type Msg
    = ToOS OS.Bus.Action
    | SelectLog LogID
    | DeselectLog


type alias Model =
    { serverId : ServerID
    , selectedLog : Maybe LogID
    }



-- Model


filterLogs : Model -> Game.Model -> List Log
filterLogs model game =
    -- TODO: Currently this is not doing any filtering other than grabbing all logs in the server
    let
        server =
            Game.getGateway game model.serverId
    in
    Server.listLogs server



-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ToOS _ ->
            ( model, Effect.none )

        SelectLog logId ->
            ( { model | selectedLog = Just logId }, Effect.none )

        DeselectLog ->
            ( { model | selectedLog = Nothing }, Effect.none )



-- View


view : Model -> Game.Model -> UI Msg
view model game =
    col [ cl "app-log-viewer", UI.flexFill ]
        [ vHeader
        , vBody model game
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

        logFn =
            \log ->
                case model.selectedLog of
                    Just selectedId ->
                        if selectedId == log.id then
                            vSelectedLogRow log

                        else
                            vLogRow log

                    Nothing ->
                        vLogRow log
    in
    List.map logFn logs



-- [ row [] [ text "a1" ], row [] [ text "a2" ] ]


vLogRow : Log -> UI Msg
vLogRow log =
    let
        date =
            "26/01/2019"

        time =
            "19:29:18"

        -- microseconds =
        --     ".123"
        vLogRowDateTime =
            col [ cl "a-log-row-date", UI.centerItems ]
                [ row [ UI.centerItems, UI.heightFill ] [ text date ]
                , row [ UI.centerItems, UI.heightFill ]
                    [ text time

                    -- TODO: Maybe only show microseconds when log is selected?
                    -- , div [ cl "a-log-row-date-microseconds" ] [ text microseconds ]
                    ]
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


vSelectedLogRow : Log -> UI Msg
vSelectedLogRow log =
    let
        date =
            "26/01/2019"

        time =
            "19:29:18"

        -- microseconds =
        --     ".123"
        vLogRowDateTime =
            col [ cl "a-log-row-date", UI.centerItems ]
                [ row [ UI.centerItems, UI.heightFill ] [ text date ]
                , row [ UI.centerItems, UI.heightFill ]
                    [ text time

                    -- TODO: Maybe only show microseconds when log is selected?
                    -- , div [ cl "a-log-row-date-microseconds" ] [ text microseconds ]
                    ]
                ]

        vLogRowInternalSeparator =
            div [ cl "a-log-row-internal-separator" ] []

        vLogRowText =
            row [ cl "a-log-row-text", UI.centerItems ] [ text log.rawText ]

        vLogRowHorizontalSeparator =
            div [ cl "a-log-row-vertical-separator" ] []

        vLogContentRow =
            row []
                [ vLogRowDateTime
                , vLogRowInternalSeparator
                , vLogRowText
                ]

        vLogActionsRow =
            row [ cl "a-log-srow-actions", UI.centerXY ]
                [ text "Actions icons here" ]
    in
    col
        [ cl "a-log-srow"
        , HE.onClick DeselectLog
        ]
        [ vLogContentRow
        , vLogRowHorizontalSeparator
        , vLogActionsRow
        ]



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
didOpen { serverId } =
    ( { serverId = serverId
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
