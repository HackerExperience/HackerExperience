module OS exposing (..)

import Apps.Demo as Demo
import Apps.Manifest as App
import Apps.Popups.ConfirmationDialog as ConfirmationDialog
import Apps.Popups.DemoSingleton as DemoSingleton
import Apps.Types as Apps
import Dict exposing (Dict)
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Events as HE
import Json.Decode as JD
import List.Extra as List exposing (Step(..))
import Maybe.Extra as Maybe
import OS.AppID exposing (AppID)
import OS.Bus
import Process
import Task
import UI exposing (UI, cl, col, id, row, style, text)
import UI.Button
import UI.Icon
import Utils
import WM
import WM.Windowable


type Msg
    = PerformAction OS.Bus.Action
    | AppMsg Apps.Msg
    | StartDrag AppID Float Float
    | Drag Float Float
    | StopDrag
    | BrowserVisibilityChanged


type alias Model =
    { wm : WM.Model
    , appModels : AppModels
    , appConfigs : AppConfigs
    }


type alias AppModels =
    Dict AppID Apps.Model


type alias AppConfigs =
    Dict AppID AppConfig


type alias AppConfig =
    { appType : App.Manifest }



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


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        -- Performs
        PerformAction OS.Bus.NoOp ->
            ( model, Effect.none )

        PerformAction (OS.Bus.RequestOpenApp app parentInfo) ->
            performRequestOpen model app parentInfo

        PerformAction (OS.Bus.RequestCloseApp appId) ->
            performActionOnApp model appId performRequestClose

        PerformAction (OS.Bus.RequestCloseChildren appId) ->
            performActionOnApp model appId performRequestCloseChildren

        PerformAction (OS.Bus.RequestFocusApp appId) ->
            performActionOnApp model appId performRequestFocus

        PerformAction (OS.Bus.OpenApp app parentInfo) ->
            performOpenApp model app parentInfo

        PerformAction (OS.Bus.CloseApp appId) ->
            performActionOnApp model appId performCloseApp

        PerformAction (OS.Bus.FocusApp appId) ->
            performActionOnApp model appId performFocusApp

        PerformAction (OS.Bus.FocusVibrateApp appId) ->
            performActionOnApp model appId performFocusVibrateApp

        PerformAction (OS.Bus.UnvibrateApp appId) ->
            performActionOnApp model appId performUnvibrateApp

        -- Drag
        StartDrag appId x y ->
            performActionOnApp model appId (startDrag (truncate x) (truncate y))

        Drag x y ->
            applyDrag model (truncate x) (truncate y)

        StopDrag ->
            stopDrag model

        -- NOTE: This doesn't really work with Alt-Tab. We'd need an onBlur on
        -- `window`, which needs direct JS access (ports).
        BrowserVisibilityChanged ->
            updateVisibilityChanged model

        AppMsg subMsg_ ->
            dispatchUpdateApp model subMsg_



-- Update > Performs


performActionOnApp :
    Model
    -> AppID
    -> (Model -> AppID -> ( Model, Effect Msg ))
    -> ( Model, Effect Msg )
performActionOnApp model appId fun =
    case WM.windowExists model.wm appId of
        True ->
            fun model appId

        -- TODO: Display OSErrorPopup when this happens
        False ->
            ( model, Effect.none )


performRequestOpen :
    Model
    -> App.Manifest
    -> Maybe WM.ParentInfo
    -> ( Model, Effect Msg )
performRequestOpen model app parentInfo =
    let
        appId =
            model.wm.nextAppId

        windowInfo =
            WM.createWindowInfo app appId parentInfo

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
            case isParentActionBlocking of
                True ->
                    Maybe.withDefault OS.Bus.NoOp parentAction

                False ->
                    WM.Windowable.willOpen app windowInfo

        finalAction =
            case action of
                OS.Bus.OpenApp targetApp parentInfo_ ->
                    WM.willOpenApp model.wm targetApp windowConfig parentInfo_ action

                _ ->
                    action
    in
    ( model, Effect.msgToCmd (PerformAction finalAction) )


performRequestClose : Model -> AppID -> ( Model, Effect Msg )
performRequestClose model appId =
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


performRequestCloseChildren : Model -> AppID -> ( Model, Effect Msg )
performRequestCloseChildren model parentId =
    let
        parentWindow =
            WM.getWindow model.wm.windows parentId

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


performRequestFocus : Model -> AppID -> ( Model, Effect Msg )
performRequestFocus model appId =
    let
        window =
            WM.getWindow model.wm.windows appId

        action =
            WM.Windowable.willFocus window.app appId window
    in
    ( model, Effect.msgToCmd (PerformAction action) )


performOpenApp :
    Model
    -> App.Manifest
    -> Maybe WM.ParentInfo
    -> ( Model, Effect Msg )
performOpenApp model app parentInfo =
    let
        appId =
            model.wm.nextAppId

        windowInfo =
            WM.createWindowInfo app appId parentInfo

        windowConfig =
            WM.Windowable.getWindowConfig windowInfo

        ( initialAppModel, appMsg ) =
            WM.Windowable.didOpen app appId windowInfo

        -- TODO: Handle parentAction
        ( parentModel, parentCmd, parentAction ) =
            case parentInfo of
                Just ( parentApp, parentId ) ->
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
            WM.registerApp model.wm app appId windowConfig parentInfo

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


performCloseApp : Model -> AppID -> ( Model, Effect Msg )
performCloseApp model appId =
    let
        -- TODO: Implement didClose if we need to do in-app clean-up
        window =
            WM.getWindow model.wm.windows appId

        -- TODO: Handle parentAction
        ( parentModel, parentCmd, parentAction ) =
            -- When the window we are closing is a child, notify the parent
            case window.parent of
                Just ( parentApp, parentId ) ->
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
            WM.deregisterApp model.wm appId
                |> maybeRemoveChildrenWindows linkedChildren

        newAppModels =
            Dict.remove appId model.appModels
                |> maybeUpdateParentModel window.parent parentModel
                |> maybeRemoveChildrenModels linkedChildren

        newAppConfigs =
            Dict.remove appId model.appConfigs
                |> maybeRemoveChildrenConfigs linkedChildren
    in
    ( { model | appModels = newAppModels, appConfigs = newAppConfigs, wm = newWm }, parentCmd )


maybeRemoveChildrenWindows : List ( App.Manifest, AppID ) -> WM.Model -> WM.Model
maybeRemoveChildrenWindows linkedChildren wm =
    List.foldl
        (\( _, childId ) accWm -> WM.deregisterApp accWm childId)
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


performFocusApp : Model -> AppID -> ( Model, Effect Msg )
performFocusApp model appId =
    ( { model | wm = WM.focusApp model.wm appId }, Effect.none )


performFocusVibrateApp : Model -> AppID -> ( Model, Effect Msg )
performFocusVibrateApp model appId =
    let
        -- TODO: Also zIndex + 1 the parent popup
        -- TODO: Move to util
        cmd =
            Effect.msgToCmdWithDelay 1000.0 (PerformAction <| OS.Bus.UnvibrateApp appId)
    in
    ( { model | wm = WM.focusVibrateApp model.wm appId }, cmd )


performUnvibrateApp : Model -> AppID -> ( Model, Effect Msg )
performUnvibrateApp model appId =
    ( { model | wm = WM.unvibrateApp model.wm appId }, Effect.none )



-- Update > Drag


startDrag : WM.X -> WM.Y -> Model -> AppID -> ( Model, Effect Msg )
startDrag x y model appId =
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
    case WM.isDragging model.wm of
        True ->
            ( { model | wm = WM.stopDrag model.wm }, Effect.none )

        False ->
            ( model, Effect.none )



-- Update > Apps


dispatchUpdateApp : Model -> Apps.Msg -> ( Model, Effect Msg )
dispatchUpdateApp model appMsg =
    case appMsg of
        Apps.InvalidMsg ->
            ( model, Effect.none )

        Apps.DemoMsg appId (Demo.ToOS busAction) ->
            ( model, Effect.msgToCmd (PerformAction busAction) )

        Apps.DemoMsg appId subMsg ->
            case getAppModel model.appModels appId of
                Apps.DemoModel appModel ->
                    updateApp
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

        Apps.PopupDemoSingletonMsg popupId (DemoSingleton.ToApp appId app action) ->
            let
                newAppMsg =
                    PerformAction OS.Bus.NoOp
            in
            ( model, Effect.msgToCmd newAppMsg )


updateApp :
    Model
    -> AppID
    -> appModel
    -> appMsg
    -> (appModel -> Apps.Model)
    -> (AppID -> appMsg -> Apps.Msg)
    -> (appMsg -> appModel -> ( appModel, Effect appMsg ))
    -> ( Model, Effect Msg )
updateApp model appId appModel appMsg toAppModel toAppMsg updateFn =
    let
        ( newAppModel, appCmd ) =
            updateFn appMsg appModel

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



-- View


documentView : Model -> UI.Document Msg
documentView model =
    { title = "", body = view model }


view : Model -> List (UI Msg)
view model =
    [ col
        [ id "hexOS"
        , maybeAddGlobalMouseMoveEvent model.wm
        ]
        [ viewTopBar model
        , wmView model
        , viewDock model
        ]
    ]


viewTopBar : Model -> UI Msg
viewTopBar model =
    row [ id "os-top" ] [ text "top" ]


wmView : Model -> UI Msg
wmView model =
    let
        windowsNodes =
            Dict.foldl (viewWindow model) [] model.wm.windows
    in
    UI.div [ id "os-wm" ]
        windowsNodes


viewWindow : Model -> AppID -> WM.Window -> List (UI Msg) -> List (UI Msg)
viewWindow model appId window acc =
    case window.isVisible of
        True ->
            let
                appModel =
                    getAppModel model.appModels appId

                windowContent =
                    Html.map AppMsg <| renderWindowContent appId window appModel

                renderedWindow =
                    renderWindow model.wm appId window windowContent
            in
            renderedWindow :: acc

        False ->
            acc


renderWindow : WM.Model -> AppID -> WM.Window -> UI Msg -> UI Msg
renderWindow wm appId window renderedContent =
    let
        isFocused =
            WM.isFocusedApp wm appId

        isBlocked =
            Maybe.isJust window.blockedByApp
    in
    col
        [ UI.id <| "app-" ++ String.fromInt appId
        , cl "os-w"
        , style "left" (String.fromInt window.posX ++ "px")
        , style "top" (String.fromInt window.posY ++ "px")
        , style "width" (String.fromInt window.lenX ++ "px")
        , style "height" (String.fromInt window.lenY ++ "px")
        , style "z-index" (String.fromInt window.zIndex)
        , addFocusedWindowClass isFocused isBlocked
        , addFocusEvent isFocused isBlocked appId
        , case window.isVibrating of
            True ->
                cl "os-w-vibrating"

            False ->
                UI.emptyAttr
        ]
        [ renderWindowTitle appId window (WM.isDraggingApp wm appId)
        , renderedContent
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
            UI.div
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
                [ closeButtonHtml ]
    in
    row
        [ cl "os-w-header"
        , UI.noSelect
        , case isDragging of
            True ->
                -- TODO: Consider data attribute instead
                cl "os-w-title-dragging"

            False ->
                UI.emptyAttr
        , onMouseDownEvent appId
        , HE.onMouseUp StopDrag
        ]
        [ titleHtml
        , buttonsHtml
        ]


stopPropagation : String -> UI.Attribute Msg
stopPropagation event =
    HE.stopPropagationOn event
        (JD.map (\msg -> ( msg, True ))
            (JD.succeed <| PerformAction OS.Bus.NoOp)
        )


renderWindowContent : AppID -> WM.Window -> Apps.Model -> UI Apps.Msg
renderWindowContent appId window appModel =
    case appModel of
        Apps.InvalidModel ->
            UI.emptyEl

        Apps.DemoModel model ->
            Html.map (Apps.DemoMsg appId) <| Demo.view model

        Apps.PopupConfirmationDialogModel model ->
            Html.map (Apps.PopupConfirmationDialogMsg appId) <| ConfirmationDialog.view model

        Apps.PopupDemoSingletonModel model ->
            Html.map (Apps.PopupDemoSingletonMsg appId) <| DemoSingleton.view model


onMouseDownEvent : AppID -> UI.Attribute Msg
onMouseDownEvent appId =
    HE.on "mousedown" <|
        JD.map2 (\x y -> StartDrag appId x y)
            (JD.field "clientX" JD.float)
            (JD.field "clientY" JD.float)


maybeAddGlobalMouseMoveEvent : WM.Model -> UI.Attribute Msg
maybeAddGlobalMouseMoveEvent wm =
    case WM.isDragging wm of
        True ->
            HE.on "mousemove" <|
                JD.map2 (\x y -> Drag x y)
                    (JD.field "clientX" JD.float)
                    (JD.field "clientY" JD.float)

        False ->
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


viewDock : Model -> UI Msg
viewDock model =
    row [ id "os-dock" ]
        [ row [ cl "os-dock-launch-tmp" ]
            [ UI.Icon.iAdd (Just "Launch Demo")
                |> UI.Button.fromIcon
                |> UI.Button.withOnClick (PerformAction (OS.Bus.RequestOpenApp App.DemoApp Nothing))
                |> UI.Button.toUI
            ]
        ]
