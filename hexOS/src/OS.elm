module OS exposing
    ( AppConfigs
    , AppModels
    , Model
    , Msg(..)
    , documentView
    , init
    , subscriptions
    , update
    , updateViewport
    )

import Apps.Demo as Demo
import Apps.LogViewer as LogViewer
import Apps.Manifest as App
import Apps.Popups.ConfirmationDialog as ConfirmationDialog
import Apps.Popups.DemoSingleton as DemoSingleton
import Apps.RemoteAccess as RemoteAccess
import Apps.Types as Apps
import Dict exposing (Dict)
import Effect exposing (Effect)
import Game
import HUD
import HUD.ConnectionInfo
import HUD.Dock
import HUD.Launcher
import Html
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as JD
import List.Extra as List exposing (Step(..))
import Maybe.Extra as Maybe
import OS.AppID exposing (AppID)
import OS.Bus
import OS.CtxMenu as CtxMenu
import State exposing (State)
import UI exposing (UI, cl, col, div, id, row, style, text)
import UI.Icon
import WM
import WM.Windowable


type alias AppModels =
    Dict AppID Apps.Model


{-| Deprecated; try to remove AppConfigs
-}
type alias AppConfigs =
    Dict AppID AppConfig


type alias AppConfig =
    { appType : App.Manifest }


type alias Model =
    { wm : WM.Model
    , appModels : AppModels
    , appConfigs : AppConfigs
    , hud : HUD.Model
    , ctxMenu : CtxMenu.Model Menu
    }


type Msg
    = PerformAction OS.Bus.Action
    | AppMsg Apps.Msg
    | StartDrag AppID Float Float
    | Drag Float Float
    | StopDrag
    | BrowserVisibilityChanged
    | HudMsg HUD.Msg
    | CtxMenuMsg (CtxMenu.Msg Menu)
    | NoOp


type Menu
    = MenuRoot



-- Model


init : WM.XY -> ( Model, Effect Msg )
init viewport =
    let
        wmModel =
            WM.init viewport
    in
    ( { wm = wmModel
      , appModels = Dict.empty
      , appConfigs = Dict.empty
      , hud = HUD.initialModel
      , ctxMenu = CtxMenu.initialModel
      }
    , Effect.none
    )


getAppModel : AppModels -> AppID -> Apps.Model
getAppModel appModels appId =
    Maybe.withDefault Apps.InvalidModel <| Dict.get appId appModels



-- getAppConfig : AppConfigs -> AppID -> AppConfig
-- getAppConfig appConfigs appId =
--     Maybe.withDefault { appType = App.InvalidApp } <| Dict.get appId appConfigs
-- getAppType : AppConfigs -> AppID -> App.Manifest
-- getAppType appConfigs appId =
--     (getAppConfig appConfigs appId).appType


updateViewport : Model -> ( WM.X, WM.Y ) -> Model
updateViewport model viewport =
    -- TODO: Add doc stating this is triggered on browser resize
    -- TODO: When resizing, we should move windows that overflow the
    -- viewport to within the viewport
    { model | wm = WM.updateViewport model.wm viewport }



-- Update


update : State -> Msg -> Model -> ( Model, Effect Msg )
update state msg model =
    case msg of
        -- Performs
        PerformAction OS.Bus.NoOp ->
            ( model, Effect.none )

        PerformAction (OS.Bus.RequestOpenApp app parentInfo) ->
            performRequestOpen state model app parentInfo

        PerformAction (OS.Bus.RequestCloseApp appId) ->
            performActionOnApp state model appId performRequestClose

        PerformAction (OS.Bus.RequestCloseChildren appId) ->
            performActionOnApp state model appId performRequestCloseChildren

        PerformAction (OS.Bus.RequestFocusApp appId) ->
            performActionOnApp state model appId performRequestFocus

        PerformAction (OS.Bus.OpenApp app parentInfo) ->
            performOpenApp state model app parentInfo

        PerformAction (OS.Bus.CloseApp appId) ->
            performActionOnApp state model appId performCloseApp

        PerformAction (OS.Bus.CollapseApp appId) ->
            performActionOnApp state model appId performCollapseApp

        PerformAction (OS.Bus.FocusApp appId) ->
            performActionOnApp state model appId performFocusApp

        PerformAction (OS.Bus.FocusVibrateApp appId) ->
            performActionOnApp state model appId performFocusVibrateApp

        PerformAction (OS.Bus.UnvibrateApp appId) ->
            performActionOnApp state model appId performUnvibrateApp

        PerformAction (OS.Bus.ToGame _) ->
            -- Handled by parent
            ( model, Effect.none )

        -- Drag
        StartDrag appId x y ->
            performActionOnApp state model appId (startDrag (truncate x) (truncate y))

        Drag x y ->
            applyDrag model (truncate x) (truncate y)

        StopDrag ->
            stopDrag model

        -- NOTE: This doesn't really work with Alt-Tab. We'd need an onBlur on
        -- `window`, which needs direct JS access (ports).
        BrowserVisibilityChanged ->
            updateVisibilityChanged model

        AppMsg appMsg ->
            dispatchUpdateApp state model appMsg

        HudMsg hudMsg ->
            updateHud state model hudMsg

        CtxMenuMsg ctxMsg ->
            let
                ( newCtxMenu, ctxMenuEffect ) =
                    CtxMenu.update ctxMsg model.ctxMenu
            in
            ( { model | ctxMenu = newCtxMenu }, Effect.map CtxMenuMsg ctxMenuEffect )

        NoOp ->
            ( model, Effect.none )



-- Update > Performs


performActionOnApp :
    State
    -> Model
    -> AppID
    -> (State -> Model -> AppID -> ( Model, Effect Msg ))
    -> ( Model, Effect Msg )
performActionOnApp state model appId fun =
    if WM.windowExists model.wm appId then
        fun state model appId
        -- TODO: Display OSErrorPopup when this happens

    else
        ( model, Effect.none )


performRequestOpen :
    State
    -> Model
    -> App.Manifest
    -> Maybe WM.ParentInfo
    -> ( Model, Effect Msg )
performRequestOpen { currentSession } model app parentInfo =
    let
        appId =
            model.wm.nextAppId

        windowInfo =
            WM.createWindowInfo currentSession app appId parentInfo

        windowConfig =
            WM.Windowable.getWindowConfig windowInfo

        parentAction =
            case parentInfo of
                Just ( _, parentId ) ->
                    Just <|
                        WM.Windowable.willOpenChild
                            app
                            (getAppModel model.appModels parentId)
                            (WM.getWindow model.wm.windows parentId)
                            windowInfo

                Nothing ->
                    Nothing

        isParentActionBlocking =
            case parentAction of
                Just (OS.Bus.OpenApp _ _) ->
                    False

                Just _ ->
                    True

                Nothing ->
                    False

        action =
            if isParentActionBlocking then
                Maybe.withDefault OS.Bus.NoOp parentAction

            else
                WM.Windowable.willOpen app windowInfo

        finalAction =
            case action of
                OS.Bus.OpenApp targetApp parentInfo_ ->
                    WM.willOpenApp model.wm targetApp windowConfig parentInfo_ action

                _ ->
                    action
    in
    ( model, Effect.msgToCmd (PerformAction finalAction) )


performRequestClose : State -> Model -> AppID -> ( Model, Effect Msg )
performRequestClose _ model appId =
    let
        window =
            WM.getWindow model.wm.windows appId

        baseAction =
            WM.Windowable.willClose window (getAppModel model.appModels appId)

        {- If the app will be closed, then we look if it has linked children.
           If it does, we will make sure these children can also be closed. If
           they can, _then_ all of them will be closed (parent and children).
        -}
        action =
            case baseAction of
                OS.Bus.CloseApp _ ->
                    if WM.hasLinkedChildren model.wm appId then
                        OS.Bus.RequestCloseChildren appId

                    else
                        baseAction

                otherAction ->
                    otherAction
    in
    ( model, Effect.msgToCmd (PerformAction action) )


performRequestCloseChildren : State -> Model -> AppID -> ( Model, Effect Msg )
performRequestCloseChildren _ model parentId =
    let
        children =
            WM.getLinkedChildren model.wm parentId

        -- TODO: Also return model and msg for each child
        -- For each children, trigger their "willClose"
        unifiedAction =
            List.stoppableFoldl
                (requestCloseChild model)
                OS.Bus.NoOp
                children

        action =
            case unifiedAction of
                OS.Bus.NoOp ->
                    OS.Bus.CloseApp parentId

                _ ->
                    unifiedAction
    in
    ( model, Effect.msgToCmd (PerformAction action) )



-- NOTE: This type may become more complex once we add child models and msgs, so keep it for now


type alias CloseChildrenAccumulator =
    OS.Bus.Action


requestCloseChild :
    Model
    -> ( App.Manifest, AppID )
    -> CloseChildrenAccumulator
    -> Step CloseChildrenAccumulator
requestCloseChild model ( _, childId ) onReject =
    let
        childWindow =
            WM.getWindow model.wm.windows childId

        baseAction =
            WM.Windowable.willClose
                childWindow
                (getAppModel model.appModels childId)
    in
    case baseAction of
        OS.Bus.CloseApp _ ->
            Continue onReject

        _ ->
            Stop baseAction


performRequestFocus : State -> Model -> AppID -> ( Model, Effect Msg )
performRequestFocus _ model appId =
    let
        window =
            WM.getWindow model.wm.windows appId

        action =
            WM.Windowable.willFocus window.app appId window
    in
    ( model, Effect.msgToCmd (PerformAction action) )


performOpenApp :
    State
    -> Model
    -> App.Manifest
    -> Maybe WM.ParentInfo
    -> ( Model, Effect Msg )
performOpenApp { currentUniverse, currentSession } model app parentInfo =
    let
        appId =
            model.wm.nextAppId

        windowInfo =
            WM.createWindowInfo currentSession app appId parentInfo

        windowConfig =
            WM.Windowable.getWindowConfig windowInfo

        -- TODO: Handle appMsg__
        ( initialAppModel, appMsg__ ) =
            WM.Windowable.didOpen app appId windowInfo

        -- TODO: Handle parentAction__
        ( parentModel, parentCmd, parentAction__ ) =
            case parentInfo of
                Just ( _, parentId ) ->
                    let
                        ( parentModel_, parentCmd_, parentAction_ ) =
                            WM.Windowable.didOpenChild
                                parentId
                                (getAppModel model.appModels parentId)
                                ( app, appId )
                                windowInfo
                    in
                    ( Just parentModel_, Effect.map AppMsg parentCmd_, parentAction_ )

                Nothing ->
                    ( Nothing, Effect.none, OS.Bus.NoOp )

        newWm =
            WM.registerApp model.wm currentUniverse currentSession app appId windowConfig parentInfo

        newAppModels =
            Dict.insert appId initialAppModel model.appModels
                |> maybeUpdateParentModel parentInfo parentModel

        osCmd =
            case windowConfig.misc of
                Just { vibrateOnOpen } ->
                    if vibrateOnOpen then
                        Effect.msgToCmdWithDelay 1000.0
                            (PerformAction <| OS.Bus.UnvibrateApp appId)

                    else
                        Effect.none

                Nothing ->
                    Effect.none

        appConfig =
            { appType = app }

        newAppConfigs =
            Dict.insert appId appConfig model.appConfigs
    in
    ( { model
        | appModels = newAppModels
        , appConfigs = newAppConfigs
        , wm = newWm
      }
    , Effect.batch
        [ osCmd
        , parentCmd
        ]
    )


performCloseApp : State -> Model -> AppID -> ( Model, Effect Msg )
performCloseApp { currentSession } model appId =
    let
        -- TODO: Implement didClose if we need to do in-app clean-up
        window =
            WM.getWindow model.wm.windows appId

        -- TODO: Handle parentAction
        ( parentModel, parentCmd, parentAction__ ) =
            -- When the window we are closing is a child, notify the parent
            case window.parent of
                Just ( _, parentId ) ->
                    let
                        ( parentModel_, parentCmd_, parentAction_ ) =
                            WM.Windowable.didCloseChild
                                parentId
                                (getAppModel model.appModels parentId)
                                ( window.app, appId )
                                window
                    in
                    ( Just parentModel_, Effect.map AppMsg parentCmd_, parentAction_ )

                Nothing ->
                    ( Nothing, Effect.none, OS.Bus.NoOp )

        linkedChildren =
            WM.getLinkedChildren model.wm appId

        newWm =
            WM.deregisterApp model.wm currentSession appId
                |> maybeRemoveChildrenWindows currentSession linkedChildren

        newAppModels =
            Dict.remove appId model.appModels
                |> maybeUpdateParentModel window.parent parentModel
                |> maybeRemoveChildrenModels linkedChildren

        newAppConfigs =
            Dict.remove appId model.appConfigs
                |> maybeRemoveChildrenConfigs linkedChildren
    in
    ( { model | appModels = newAppModels, appConfigs = newAppConfigs, wm = newWm }, parentCmd )


performCollapseApp : State -> Model -> AppID -> ( Model, Effect Msg )
performCollapseApp { currentSession } model appId =
    let
        newWm =
            WM.collapseApp model.wm currentSession appId
    in
    ( { model | wm = newWm }, Effect.none )


maybeRemoveChildrenWindows : WM.SessionID -> List ( App.Manifest, AppID ) -> WM.Model -> WM.Model
maybeRemoveChildrenWindows sessionId linkedChildren wm =
    List.foldl
        (\( _, childId ) accWm -> WM.deregisterApp accWm sessionId childId)
        wm
        linkedChildren


maybeRemoveChildrenModels : List ( App.Manifest, AppID ) -> AppModels -> AppModels
maybeRemoveChildrenModels linkedChildren appModels =
    List.foldl
        (\( _, childId ) accAppModels -> Dict.remove childId accAppModels)
        appModels
        linkedChildren


maybeRemoveChildrenConfigs : List ( App.Manifest, AppID ) -> AppConfigs -> AppConfigs
maybeRemoveChildrenConfigs linkedChildren appConfigs =
    List.foldl
        (\( _, childId ) accAppConfigs -> Dict.remove childId accAppConfigs)
        appConfigs
        linkedChildren


performFocusApp : State -> Model -> AppID -> ( Model, Effect Msg )
performFocusApp { currentSession } model appId =
    ( { model | wm = WM.focusApp model.wm currentSession appId }, Effect.none )


performFocusVibrateApp : State -> Model -> AppID -> ( Model, Effect Msg )
performFocusVibrateApp { currentSession } model appId =
    let
        -- TODO: Also zIndex + 1 the parent popup
        cmd =
            Effect.msgToCmdWithDelay 1000.0 (PerformAction <| OS.Bus.UnvibrateApp appId)
    in
    ( { model | wm = WM.focusVibrateApp model.wm currentSession appId }, cmd )


performUnvibrateApp : State -> Model -> AppID -> ( Model, Effect Msg )
performUnvibrateApp _ model appId =
    ( { model | wm = WM.unvibrateApp model.wm appId }, Effect.none )



-- Update > Drag


startDrag : WM.X -> WM.Y -> State -> Model -> AppID -> ( Model, Effect Msg )
startDrag x y _ model appId =
    ( { model | wm = WM.startDrag model.wm appId x y }, Effect.none )


applyDrag : Model -> WM.X -> WM.Y -> ( Model, Effect Msg )
applyDrag model x y =
    ( { model | wm = WM.applyDrag model.wm x y }, Effect.none )


stopDrag : Model -> ( Model, Effect Msg )
stopDrag model =
    ( { model | wm = WM.stopDrag model.wm }, Effect.none )



-- Update > Browser Events


updateVisibilityChanged : Model -> ( Model, Effect Msg )
updateVisibilityChanged model =
    if WM.isDragging model.wm then
        ( { model | wm = WM.stopDrag model.wm }, Effect.none )

    else
        ( model, Effect.none )



-- Update > Apps


dispatchUpdateApp : State -> Model -> Apps.Msg -> ( Model, Effect Msg )
dispatchUpdateApp state model appMsg =
    case appMsg of
        Apps.InvalidMsg ->
            ( model, Effect.none )

        Apps.LogViewerMsg _ (LogViewer.ToOS busAction) ->
            ( model, Effect.msgToCmd (PerformAction busAction) )

        Apps.LogViewerMsg appId subMsg ->
            case getAppModel model.appModels appId of
                Apps.LogViewerModel appModel ->
                    updateApp
                        state
                        model
                        appId
                        appModel
                        subMsg
                        Apps.LogViewerModel
                        Apps.LogViewerMsg
                        LogViewer.update

                _ ->
                    ( model, Effect.none )

        Apps.RemoteAccessMsg _ (RemoteAccess.ToOS busAction) ->
            ( model, Effect.msgToCmd (PerformAction busAction) )

        Apps.RemoteAccessMsg appId subMsg ->
            case getAppModel model.appModels appId of
                Apps.RemoteAccessModel appModel ->
                    updateApp
                        state
                        model
                        appId
                        appModel
                        subMsg
                        Apps.RemoteAccessModel
                        Apps.RemoteAccessMsg
                        RemoteAccess.update

                _ ->
                    ( model, Effect.none )

        Apps.DemoMsg _ (Demo.ToOS busAction) ->
            ( model, Effect.msgToCmd (PerformAction busAction) )

        Apps.DemoMsg appId subMsg ->
            case getAppModel model.appModels appId of
                Apps.DemoModel appModel ->
                    updateApp
                        state
                        model
                        appId
                        appModel
                        subMsg
                        Apps.DemoModel
                        Apps.DemoMsg
                        Demo.update

                _ ->
                    ( model, Effect.none )

        -- Popups
        Apps.PopupConfirmationDialogMsg popupId (ConfirmationDialog.ToApp appId app action) ->
            let
                newAppMsg =
                    case app of
                        App.DemoApp ->
                            AppMsg
                                (Apps.DemoMsg
                                    appId
                                 <|
                                    Demo.FromConfirmationDialog popupId action
                                )

                        _ ->
                            -- OS error window re. unhandled app type
                            PerformAction OS.Bus.NoOp
            in
            ( model, Effect.msgToCmd newAppMsg )

        Apps.PopupDemoSingletonMsg _ (DemoSingleton.ToApp _ _ _) ->
            let
                newAppMsg =
                    PerformAction OS.Bus.NoOp
            in
            ( model, Effect.msgToCmd newAppMsg )


updateApp :
    State
    -> Model
    -> AppID
    -> appModel
    -> appMsg
    -> (appModel -> Apps.Model)
    -> (AppID -> appMsg -> Apps.Msg)
    -> (Game.Model -> appMsg -> appModel -> ( appModel, Effect appMsg ))
    -> ( Model, Effect Msg )
updateApp state model appId appModel appMsg toAppModel toAppMsg updateFn =
    let
        -- TODO: Same comment as viewWindow:
        -- In fact, it may make sense for each App to implement a "stateFilter", thus letting
        -- each App decide which data it receives (based on its own needs)
        game =
            State.getActiveUniverse state

        ( newAppModel, appCmd ) =
            updateFn game appMsg appModel

        midCmd =
            Effect.map (toAppMsg appId) appCmd

        newAppModels =
            Dict.insert appId (toAppModel newAppModel) model.appModels
    in
    ( { model | appModels = newAppModels }, Effect.batch [ Effect.map AppMsg midCmd ] )


maybeUpdateParentModel : Maybe WM.ParentInfo -> Maybe Apps.Model -> AppModels -> AppModels
maybeUpdateParentModel parentInfo parentModel appModels =
    case ( parentInfo, parentModel ) of
        ( Just ( _, parentId ), Just newParentModel ) ->
            Dict.insert parentId newParentModel appModels

        _ ->
            appModels



-- Update > HUD


updateHud : State -> Model -> HUD.Msg -> ( Model, Effect Msg )
updateHud state model hudMsg =
    case hudMsg of
        HUD.CIMsg (HUD.ConnectionInfo.ToOS action) ->
            ( model, Effect.msgToCmd (PerformAction action) )

        HUD.DockMsg (HUD.Dock.ToOS action) ->
            ( model, Effect.msgToCmd (PerformAction action) )

        HUD.LauncherMsg (HUD.Launcher.ToOS action) ->
            ( model, Effect.msgToCmd (PerformAction action) )

        _ ->
            let
                ( newHud, hudEffect ) =
                    HUD.update state hudMsg model.hud
            in
            ( { model | hud = newHud }, Effect.map HudMsg hudEffect )



-- View


documentView : State -> Model -> UI.Document Msg
documentView gameState model =
    { title = "", body = view gameState model }


view : State -> Model -> List (UI Msg)
view gameState model =
    [ col
        (id "hexOS" :: addGlobalEvents model)
        [ wmView gameState model
        , Html.map HudMsg <| HUD.view gameState model.hud model.wm
        , CtxMenu.view model.ctxMenu CtxMenuMsg ctxMenuConfig model
        ]
    ]


ctxMenuConfig : Menu -> Model -> CtxMenu.Config Msg Menu
ctxMenuConfig menu model =
    case menu of
        MenuRoot ->
            let
                msg =
                    PerformAction (OS.Bus.RequestOpenApp App.DemoApp Nothing)

                entries =
                    [ CtxMenu.SimpleItem
                        { label = "Option 1"
                        , enabled = True
                        , onClick = Just msg
                        }
                    , CtxMenu.SimpleItem
                        { label = "Option 2"
                        , enabled = False
                        , onClick = Just msg
                        }
                    , CtxMenu.SimpleItem
                        { label = "Option 3"
                        , enabled = True
                        , onClick = Nothing
                        }
                    , CtxMenu.Divisor
                    , CtxMenu.SimpleItem
                        { label = "Option 4"
                        , enabled = True
                        , onClick = Nothing
                        }
                    , CtxMenu.SimpleItem
                        { label = "Option 5"
                        , enabled = True
                        , onClick = Nothing
                        }
                    , CtxMenu.SimpleItem
                        { label = "Option 6"
                        , enabled = True
                        , onClick = Nothing
                        }
                    ]
            in
            { entries = entries
            , mapper = CtxMenuMsg
            }



-- TODO: Move to another part of this module if this is confirmed to be accurate


addGlobalEvents : Model -> List (UI.Attribute Msg)
addGlobalEvents model =
    maybeAddGlobalMouseMoveEvent model.wm
        :: HA.map CtxMenuMsg (CtxMenu.event MenuRoot)
        :: List.map (HA.map HudMsg) (HUD.addGlobalEvents model.hud)


wmView : State -> Model -> UI Msg
wmView gameState model =
    let
        windowsNodes =
            Dict.foldl (viewWindow gameState model) [] model.wm.windows
    in
    div
        [ id "os-wm"
        ]
        windowsNodes


viewWindow : State -> Model -> AppID -> WM.Window -> List (UI Msg) -> List (UI Msg)
viewWindow state model appId window acc =
    if shouldRenderWindow state window then
        let
            appModel =
                getAppModel model.appModels appId

            game =
                State.getActiveUniverse state

            -- TODO: it may make sense for each App to implement a "stateFilter", thus letting
            -- each App decide which data it receives (based on its own needs)
            windowContent =
                Html.map AppMsg <| getWindowInnerContent appId window appModel game

            renderedWindow =
                renderWindow state.currentSession model.wm appId window windowContent
        in
        renderedWindow :: acc

    else
        acc


{-| A window should be rendered if:

1.  It is registered to the same Universe the OS is using; and
2.  It is registered to the same Server the WM is using; and
3.  It has the `isVisible` flag set to True (it's not collapsed).

-}
shouldRenderWindow : State -> WM.Window -> Bool
shouldRenderWindow state window =
    -- TODO: maybe move this function to WM?
    window.isVisible && window.universe == state.currentUniverse && window.sessionID == state.currentSession


renderWindow : WM.SessionID -> WM.Model -> AppID -> WM.Window -> UI Msg -> UI Msg
renderWindow sessionId wm appId window renderedContent =
    let
        isFocused =
            WM.isFocusedApp wm sessionId appId

        isBlocked =
            Maybe.isJust window.blockedByApp
    in
    col
        [ id <| "app-" ++ String.fromInt appId
        , HA.map CtxMenuMsg CtxMenu.noop
        , cl "os-w"
        , style "left" (String.fromInt window.posX ++ "px")
        , style "top" (String.fromInt window.posY ++ "px")
        , style "width" (String.fromInt window.lenX ++ "px")
        , style "height" (String.fromInt window.lenY ++ "px")
        , style "z-index" (String.fromInt window.zIndex)
        , addFocusedWindowClass isFocused isBlocked
        , addFocusEvent isFocused isBlocked appId
        , if window.isVibrating then
            cl "os-w-vibrating"

          else
            UI.emptyAttr
        ]
        [ renderWindowTitle appId window (WM.isDraggingApp wm appId)
        , renderWindowContent renderedContent
        , windowBlockingOverlay window
        ]


{-| This is a hack until we can think of a better solution. This overlay will be
rendered in front of the entire window when it is blocked by a popup, thus
ensuring that any clicks to it FocusVibrate the popup instead.
-}
windowBlockingOverlay : WM.Window -> UI Msg
windowBlockingOverlay window =
    case window.blockedByApp of
        Just popupId ->
            div
                [ cl "os-w-app-overlay"
                , HE.onClick (PerformAction <| OS.Bus.FocusVibrateApp popupId)
                ]
                []

        Nothing ->
            UI.emptyEl


renderWindowTitle : AppID -> WM.Window -> Bool -> UI Msg
renderWindowTitle appId window isDragging =
    let
        titleHtml =
            row [ cl "os-w-title" ]
                [ text window.title ]

        collapseButtonHtml =
            UI.Icon.msOutline "minimize" Nothing
                |> UI.Icon.withOnClick (PerformAction <| OS.Bus.CollapseApp appId)
                |> UI.Icon.toUI

        closeButtonHtml =
            UI.Icon.iClose Nothing
                |> UI.Icon.withOnClick (PerformAction <| OS.Bus.RequestCloseApp appId)
                |> UI.Icon.toUI

        buttonsHtml =
            row
                [ cl "os-w-title-actions"
                , stopPropagation "mousedown"
                , stopPropagation "mouseup"
                ]
                [ collapseButtonHtml
                , closeButtonHtml
                ]
    in
    row
        [ cl "os-w-header"
        , if isDragging then
            -- TODO: Consider data attribute instead
            cl "os-w-title-dragging"

          else
            UI.emptyAttr
        , onMouseDownEvent appId
        , HE.onMouseUp StopDrag
        ]
        [ titleHtml
        , buttonsHtml
        ]


renderWindowContent : UI Msg -> UI Msg
renderWindowContent innerContent =
    col [ cl "os-w-content" ] [ innerContent ]


stopPropagation : String -> UI.Attribute Msg
stopPropagation event =
    HE.stopPropagationOn event
        (JD.succeed <| (\msg -> ( msg, True )) (PerformAction OS.Bus.NoOp))


getWindowInnerContent : AppID -> WM.Window -> Apps.Model -> Game.Model -> UI Apps.Msg
getWindowInnerContent appId _ appModel universe =
    case appModel of
        Apps.InvalidModel ->
            UI.emptyEl

        Apps.LogViewerModel model ->
            Html.map (Apps.LogViewerMsg appId) <| LogViewer.view model universe

        Apps.RemoteAccessModel model ->
            Html.map (Apps.RemoteAccessMsg appId) <| RemoteAccess.view model universe

        Apps.DemoModel model ->
            Html.map (Apps.DemoMsg appId) <| Demo.view model

        Apps.PopupConfirmationDialogModel model ->
            Html.map (Apps.PopupConfirmationDialogMsg appId) <| ConfirmationDialog.view model

        Apps.PopupDemoSingletonModel model ->
            Html.map (Apps.PopupDemoSingletonMsg appId) (DemoSingleton.view model)


onMouseDownEvent : AppID -> UI.Attribute Msg
onMouseDownEvent appId =
    HE.on "mousedown" <|
        JD.map3
            (\x y button ->
                -- Only start dragging when using left click
                if button == 0 then
                    StartDrag appId x y

                else
                    NoOp
            )
            (JD.field "clientX" JD.float)
            (JD.field "clientY" JD.float)
            (JD.field "button" JD.int)


maybeAddGlobalMouseMoveEvent : WM.Model -> UI.Attribute Msg
maybeAddGlobalMouseMoveEvent wm =
    if WM.isDragging wm then
        HE.on "mousemove" <|
            JD.map2 Drag
                (JD.field "clientX" JD.float)
                (JD.field "clientY" JD.float)

    else
        UI.emptyAttr


addFocusedWindowClass : Bool -> Bool -> UI.Attribute Msg
addFocusedWindowClass isFocused isBlocked =
    if isFocused && not isBlocked then
        cl "os-w-focused"

    else
        UI.emptyAttr


addFocusEvent : Bool -> Bool -> AppID -> UI.Attribute Msg
addFocusEvent isFocused isBlocked appId =
    if not isFocused && not isBlocked then
        HE.onMouseDown (PerformAction <| OS.Bus.RequestFocusApp appId)

    else
        UI.emptyAttr



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map CtxMenuMsg <| CtxMenu.subscriptions model.ctxMenu ]
