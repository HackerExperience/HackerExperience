module Apps.LogViewer exposing (..)

import API.Game as GameAPI
import API.Types
import Apps.Input as App
import Apps.Manifest as App
import Dict exposing (Dict)
import Effect exposing (Effect)
import Game
import Game.Bus as Game
import Game.Model.Log as Log exposing (Log, LogType(..))
import Game.Model.LogID as LogID exposing (LogID, RawLogID)
import Game.Model.NIP exposing (NIP)
import Game.Model.ProcessOperation as Operation exposing (Operation)
import Game.Model.Server as Server
import Html.Attributes as HA
import Html.Events as HE
import Maybe.Extra as Maybe
import OS.AppID exposing (AppID)
import OS.Bus
import OS.CtxMenu as CtxMenu
import OS.CtxMenu.Menus as CtxMenu
import UI exposing (UI, cl, clIf, col, div, row, text)
import UI.Icon
import WM



-- Types


type Msg
    = ToOS OS.Bus.Action
    | ToCtxMenu CtxMenu.Msg
    | OnDeleteLog Log
    | OnDeleteLogResponse LogID API.Types.LogDeleteResult
    | OnRequestOpenEditPopup Log
    | OnSelectNextRevision Log (Maybe Int)
    | OnSelectPreviousRevision Log (Maybe Int)


type alias Model =
    { appId : AppID
    , nip : NIP
    , customSelectionMap : Dict RawLogID Int
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
        OnSelectNextRevision log customSelection ->
            let
                currentRevisionId =
                    case customSelection of
                        Just id ->
                            id

                        Nothing ->
                            log.selectedRevisionId

                maxRevisionId =
                    Log.getMaxRevisionId log.revisions

                nextRevisionId =
                    if maxRevisionId == currentRevisionId then
                        currentRevisionId

                    else
                        currentRevisionId + 1

                newCustomSelectionMap =
                    Dict.insert (LogID.toString log.id) nextRevisionId model.customSelectionMap
            in
            ( { model | customSelectionMap = newCustomSelectionMap }, Effect.none )

        OnSelectPreviousRevision log customSelection ->
            let
                currentRevisionId =
                    case customSelection of
                        Just id ->
                            id

                        Nothing ->
                            log.selectedRevisionId

                nextRevisionId =
                    if currentRevisionId > 1 then
                        currentRevisionId - 1

                    else
                        1

                newCustomSelectionMap =
                    Dict.insert (LogID.toString log.id) nextRevisionId model.customSelectionMap
            in
            ( { model | customSelectionMap = newCustomSelectionMap }, Effect.none )

        OnDeleteLog log ->
            let
                server =
                    Game.getServer game model.nip

                config =
                    GameAPI.logDeleteConfig game.apiCtx model.nip log.id server.tunnelId

                toGameMsg =
                    Game.ProcessOperation
                        model.nip
                        (Operation.Starting <| Operation.LogDelete log.id)
            in
            ( model
            , Effect.batch
                [ Effect.logDelete (OnDeleteLogResponse log.id) config
                , Effect.msgToCmd <| ToOS <| OS.Bus.ToGame toGameMsg
                ]
            )

        OnDeleteLogResponse _ (Ok _) ->
            -- Side-effects are handled by the ProcessCreatedEvent
            ( model, Effect.none )

        OnDeleteLogResponse logId (Err _) ->
            let
                toGameMsg =
                    Game.ProcessOperation
                        model.nip
                        (Operation.StartFailed (Operation.LogDelete logId))
            in
            ( model, Effect.msgToCmd <| ToOS <| OS.Bus.ToGame toGameMsg )

        OnRequestOpenEditPopup log ->
            let
                msg_ =
                    ToOS <|
                        OS.Bus.RequestOpenApp
                            App.PopupLogEdit
                            (Just ( App.LogViewerApp, model.appId ))
                            (App.PopupLogEditInput model.nip log)
            in
            ( model, Effect.msgToCmd msg_ )

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
    List.map (\log -> vLogRow model log) logs


vLogRow : Model -> Log -> UI Msg
vLogRow model log =
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
            col
                [ cl "a-lr-action-entry"
                , UI.onClick <| OnRequestOpenEditPopup log
                ]
                [ editIcon ]

        deleteEntry =
            col
                [ cl "a-lr-action-entry"
                , UI.onClick <| OnDeleteLog log
                ]
                [ deleteIcon ]

        actions =
            if not log.isDeleted && Maybe.isNothing log.currentOp then
                row [ cl "a-log-row-actions" ]
                    [ editEntry, deleteEntry ]

            else
                UI.emptyEl

        customSelection =
            Dict.get (LogID.toString log.id) model.customSelectionMap

        ( minRevisionId, maxRevisionId ) =
            ( 1, Log.getMaxRevisionId log.revisions )

        revision =
            Log.getSelectedRevision log customSelection

        revUpIcon =
            row
                [ cl "a-lr-rs-arrow a-lr-rs-up"
                , clIf (revision.revisionId == maxRevisionId) "a-lr-rs-limit"
                , UI.onClick <| OnSelectNextRevision log customSelection
                ]
                []

        revDownIcon =
            row
                [ cl "a-lr-rs-arrow a-lr-rs-down"
                , clIf (revision.revisionId == minRevisionId) "a-lr-rs-limit"
                , UI.onClick <| OnSelectPreviousRevision log customSelection
                ]
                []

        revisionSelector =
            if log.revisionCount > 1 then
                row [ cl "a-log-row-revselector" ]
                    [ text <| String.fromInt revision.revisionId
                    , col [ cl "a-lr-rs-selector" ]
                        [ revUpIcon
                        , revDownIcon
                        ]
                    ]

            else
                UI.emptyEl

        logText =
            row [ cl "a-log-row-text", UI.centerItems ]
                [ text revision.rawText ]

        -- TODO: Move to dedicate function
        -- TODO: UI.Spinner?
        spinnerIcon =
            UI.Icon.msOutline "progress_activity" Nothing
                |> UI.Icon.withClass "a-lr-badge-spinner"
                |> UI.Icon.toUI

        brokenBadgeIcon =
            UI.Icon.msOutline "warning" Nothing
                |> UI.Icon.withClass "a-lr-badge-broken"
                |> UI.Icon.toUI

        deletedBadgeIcon =
            UI.Icon.msOutline "cancel" Nothing
                |> UI.Icon.withClass "a-lr-badge-deleted"
                |> UI.Icon.toUI

        statusBadges =
            case ( log.isDeleted, revision.type_ ) of
                ( True, CustomLog _ ) ->
                    [ brokenBadgeIcon, deletedBadgeIcon ]

                ( True, _ ) ->
                    [ deletedBadgeIcon ]

                ( False, CustomLog _ ) ->
                    [ brokenBadgeIcon ]

                ( False, _ ) ->
                    []

        allBadges =
            case log.currentOp of
                Nothing ->
                    statusBadges

                Just _ ->
                    spinnerIcon :: statusBadges

        badges =
            if not <| List.isEmpty allBadges then
                row [ cl "a-log-row-badges" ]
                    allBadges

            else
                UI.emptyEl
    in
    row
        [ cl "a-log-row"
        , if log.isDeleted then
            cl "a-log-row-deleted"

          else
            UI.emptyAttr
        , HA.map ToCtxMenu (CtxMenu.event <| CtxMenu.LogViewer <| CtxMenu.LVEntryMenu log)
        ]
        [ dateTime
        , separator
        , badges
        , logText
        , revisionSelector
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


willOpen : WM.WindowInfo -> App.InitialInput -> OS.Bus.Action
willOpen _ input =
    OS.Bus.OpenApp App.LogViewerApp Nothing input


didOpen : WM.WindowInfo -> App.InitialInput -> ( Model, Effect Msg )
didOpen { appId, sessionId } _ =
    let
        -- TODO: Not worrying about this for now.
        nip =
            case sessionId of
                WM.LocalSessionID nip_ ->
                    nip_

                WM.RemoteSessionID nip_ ->
                    nip_
    in
    ( { appId = appId
      , nip = nip
      , customSelectionMap = Dict.empty
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


willOpenChild :
    Model
    -> App.Manifest
    -> WM.Window
    -> WM.WindowInfo
    -> App.InitialInput
    -> OS.Bus.Action
willOpenChild _ child parentWindow _ input =
    OS.Bus.OpenApp child (Just ( App.LogViewerApp, parentWindow.appId )) input


didOpenChild :
    Model
    -> ( App.Manifest, AppID )
    -> WM.WindowInfo
    -> App.InitialInput
    -> ( Model, Effect Msg, OS.Bus.Action )
didOpenChild model _ _ _ =
    ( model, Effect.none, OS.Bus.NoOp )


didCloseChild :
    Model
    -> ( App.Manifest, AppID )
    -> WM.Window
    -> ( Model, Effect Msg, OS.Bus.Action )
didCloseChild model _ _ =
    -- TODO: Make defaults for these
    ( model, Effect.none, OS.Bus.NoOp )
