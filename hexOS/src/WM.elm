module WM exposing
    ( Model
    , ParentInfo
    , SessionID
    , Window
    , WindowConfig
    , WindowInfo
    , X
    , XY
    , Y
    , applyDrag
    , createWindowInfo
    , deregisterApp
    , dummyWindowConfig
    , focusApp
    , focusVibrateApp
    , getLinkedChildren
    , getWindow
    , hasLinkedChildren
    , init
    , isDragging
    , isDraggingApp
    , isFocusedApp
    , registerApp
    , startDrag
    , stopDrag
    , toSessionId
    , unvibrateApp
    , updateViewport
    , willOpenApp
    , windowExists
    )

{-| WM eh meio que uma model pura, enquanto que
OS gerencia as Msgs/Updates etc. Tentar fazer assim (mas tudo bem se nao rolar)
-}

import Apps.Manifest as App
import Dict exposing (Dict)
import Game.Model.ServerID as ServerID exposing (ServerID)
import Game.Universe as Universe exposing (Universe)
import List.Extra as List
import Maybe.Extra as Maybe
import OS.AppID exposing (AppID)
import OS.Bus


type SessionID
    = SessionID ServerID


type alias Model =
    { windows : Windows
    , currentSession : SessionID
    , focusedWindow : Maybe AppID
    , dragging : Maybe ( AppID, XY, XY )
    , nextAppId : Int
    , nextZIndex : Int
    , viewportX : X
    , viewportY : Y
    , hud : Hud
    }


type alias X =
    Int


type alias Y =
    Int


type alias XY =
    ( X, Y )


type alias Windows =
    Dict AppID Window


type alias Hud =
    { topHeight : Int
    , dockHeight : Int
    }


type alias Window =
    { appId : AppID
    , app : App.Manifest
    , posX : X
    , posY : Y
    , lenX : X
    , lenY : Y
    , isVisible : Bool
    , isVibrating : Bool
    , title : String
    , zIndex : Int
    , parent : Maybe ParentInfo
    , isPopup : Bool
    , children : List ( App.Manifest, AppID )
    , blockedByApp : Maybe AppID
    , childBehavior : Maybe ChildBehavior
    , universe : Universe
    , sessionID : SessionID
    }


type alias ChildBehavior =
    { closeWithParent : Bool
    , isSingleton : Bool
    }


type alias WindowInfo =
    { appId : AppID
    , app : App.Manifest
    , parent : Maybe ParentInfo
    }


type alias ParentInfo =
    ( App.Manifest, AppID )


type alias WindowConfig =
    { lenX : X
    , lenY : Y
    , title : String
    , childBehavior : Maybe ChildBehavior
    , misc : Maybe WindowConfigMisc
    }


type alias WindowConfigMisc =
    { vibrateOnOpen : Bool }


type alias ViewportLimits =
    { minX : X
    , maxX : X
    , minY : Y
    , maxY : Y
    }



-- Model


init : SessionID -> XY -> Model
init sessionID ( viewportX, viewportY ) =
    { windows = Dict.empty
    , currentSession = sessionID
    , focusedWindow = Nothing
    , nextAppId = 1
    , nextZIndex = 1
    , dragging = Nothing
    , viewportX = viewportX
    , viewportY = viewportY
    , hud =
        { topHeight = 60
        , dockHeight = 80
        }
    }


toSessionId : ServerID -> SessionID
toSessionId serverId =
    SessionID serverId


updateViewport : Model -> ( X, Y ) -> Model
updateViewport model ( vX, vY ) =
    { model | viewportX = vX, viewportY = vY }
        |> restrictWindowsViewport


{-| Iterates over the windows and makes sure they are within the viewport.
Triggered when browser resizes to a smaller viewport
-}
restrictWindowsViewport : Model -> Model
restrictWindowsViewport model =
    let
        newWindows =
            Dict.foldl
                (\appId window acc ->
                    let
                        { minX, maxX, minY, maxY } =
                            getViewportLimits model window.lenX window.lenY

                        newX =
                            clamp minX maxX window.posX

                        newY =
                            clamp minY maxY window.posY

                        newWindow =
                            if window.posX /= newX || window.posY /= newY then
                                { window | posX = newX, posY = newY }

                            else
                                window
                    in
                    Dict.insert appId newWindow acc
                )
                Dict.empty
                model.windows
    in
    { model | windows = newWindows }


getViewportLimits : Model -> X -> Y -> ViewportLimits
getViewportLimits model lenX lenY =
    { minX = 0
    , maxX = model.viewportX - lenX
    , minY = model.hud.topHeight
    , maxY = model.viewportY - model.hud.dockHeight - lenY
    }



-- Model > Windows


maybeInsertParentChildren : Window -> Maybe ParentInfo -> Windows -> Windows
maybeInsertParentChildren childWindow parentInfo windows =
    case parentInfo of
        Just ( _, parentId ) ->
            let
                ( popup, popupId ) =
                    ( childWindow.app, childWindow.appId )

                parentWindow =
                    getWindow windows parentId

                newWindow =
                    { parentWindow | children = ( popup, popupId ) :: parentWindow.children }
                        |> maybeBlockWindow childWindow
            in
            Dict.insert parentId newWindow windows

        Nothing ->
            windows


maybeRemoveParentChild : Window -> Windows -> Windows
maybeRemoveParentChild childWindow windows =
    case childWindow.parent of
        Just ( _, parentId ) ->
            let
                getNewChildren children =
                    List.filter (\( _, childId ) -> childId /= childWindow.appId) children
            in
            Dict.update
                parentId
                (Maybe.map
                    (\v ->
                        { v | children = getNewChildren v.children }
                            |> maybeUnblockWindow childWindow
                    )
                )
                windows

        Nothing ->
            windows


maybeBlockWindow : Window -> Window -> Window
maybeBlockWindow child parent =
    if isPopupBlocking child.app then
        { parent | blockedByApp = Just child.appId }

    else
        parent


maybeUnblockWindow : Window -> Window -> Window
maybeUnblockWindow child parent =
    if isPopupBlocking child.app then
        { parent | blockedByApp = Nothing }

    else
        parent



-- Model > Window


getWindow : Windows -> AppID -> Window
getWindow windows appId =
    Maybe.withDefault dummyWindow (getWindowSafe windows appId)


getWindowSafe : Windows -> AppID -> Maybe Window
getWindowSafe windows appId =
    Dict.get appId windows


createWindowInfo : App.Manifest -> AppID -> Maybe ParentInfo -> WindowInfo
createWindowInfo app appId parentInfo =
    { appId = appId
    , app = app
    , parent = parentInfo
    }



-- hasBlockingPopups : Window -> Maybe ( App.Manifest, AppID )
-- hasBlockingPopups { children } =
--     List.find (\( popup, _ ) -> isPopupBlocking popup) children


isPopupBlocking : App.Manifest -> Bool
isPopupBlocking popup =
    case popup of
        App.PopupConfirmationDialog ->
            True

        _ ->
            False


windowExists : Model -> AppID -> Bool
windowExists { windows } appId =
    Dict.get appId windows
        |> Maybe.isJust


hasLinkedChildren : Model -> AppID -> Bool
hasLinkedChildren model appId =
    List.isEmpty (getLinkedChildren model appId)
        |> not


{-| Returns all children that are linked to the parent (closes with parent)
-}
getLinkedChildren : Model -> AppID -> List ( App.Manifest, AppID )
getLinkedChildren model appId =
    List.filter
        (\( _, childId ) ->
            case (getWindow model.windows childId).childBehavior of
                Just behavior ->
                    behavior.closeWithParent

                Nothing ->
                    True
        )
        (getWindow model.windows appId).children



-- Model > Drag


startDrag : Model -> AppID -> X -> Y -> Model
startDrag model appId cX cY =
    case model.dragging of
        Just _ ->
            model

        Nothing ->
            let
                { posX, posY } =
                    getWindow model.windows appId
            in
            { model | dragging = Just ( appId, ( posX, posY ), ( cX, cY ) ) }


stopDrag : Model -> Model
stopDrag model =
    { model | dragging = Nothing }


applyDrag : Model -> X -> Y -> Model
applyDrag model x y =
    case model.dragging of
        -- TODO: I might need to remove (ox,oy) from `model.draggin` entirely
        -- No longer used
        Just ( appId, ( origPosX, origPosY ), ( cX, cY ) ) ->
            let
                { lenX, lenY } =
                    getWindow model.windows appId

                { minX, maxX, minY, maxY } =
                    getViewportLimits model lenX lenY

                -- `newX` will be the difference between the original drag
                -- position (`cX`) and the current drag position (`x`) added
                -- to the current position (`origPosX`), with limits observed.
                newX =
                    clamp minX maxX (origPosX + x - cX)

                -- See comment above to understand how `newY` is calculated.
                newY =
                    clamp minY maxY (origPosY + y - cY)

                newWindows =
                    Dict.update
                        appId
                        (Maybe.map (\v -> { v | posX = newX, posY = newY }))
                        model.windows
            in
            { model | windows = newWindows }

        Nothing ->
            model


isDragging : Model -> Bool
isDragging model =
    case model.dragging of
        Just _ ->
            True

        Nothing ->
            False


isDraggingApp : Model -> AppID -> Bool
isDraggingApp model appId =
    case model.dragging of
        Just ( id, _, _ ) ->
            id == appId

        Nothing ->
            False



-- Model > Focus


isFocusedApp : Model -> AppID -> Bool
isFocusedApp model appId =
    case model.focusedWindow of
        Just id ->
            id == appId

        Nothing ->
            False



-- Model > API
-- app


createWindow : Model -> Universe -> App.Manifest -> AppID -> WindowConfig -> Maybe ParentInfo -> Window
createWindow model universe app appId config parentInfo =
    let
        defaultChildBehavior =
            { closeWithParent = True
            , isSingleton = True
            }

        defaultMisc =
            { vibrateOnOpen = False }

        -- Windows with parent must have at least the default child behavior
        childBehavior =
            case parentInfo of
                Just _ ->
                    Maybe.withDefault defaultChildBehavior config.childBehavior
                        |> Just

                Nothing ->
                    Nothing

        misc =
            Maybe.withDefault defaultMisc config.misc
    in
    { appId = appId
    , app = app
    , posX = 100
    , posY = 100
    , lenX = config.lenX
    , lenY = config.lenY
    , title = config.title
    , isVisible = True
    , isVibrating = misc.vibrateOnOpen
    , zIndex = model.nextZIndex
    , parent = parentInfo
    , isPopup = Maybe.isJust parentInfo
    , children = []
    , blockedByApp = Nothing
    , childBehavior = childBehavior
    , universe = universe
    , sessionID = model.currentSession
    }


{-| Final verification before opening an app.

Enforces that a singleton popup is opened only once. Additional enforcements can
be added in the future.

-}
willOpenApp :
    Model
    -> App.Manifest
    -> WindowConfig
    -> Maybe ParentInfo
    -> OS.Bus.Action
    -> OS.Bus.Action
willOpenApp model app _ parentInfo openAction =
    case parentInfo of
        Just ( _, parentId ) ->
            let
                -- isSingleton =
                --     case windowConfig.childBehavior of
                --         Just behavior ->
                --             behavior.isSingleton
                --         Nothing ->
                --             True
                parentChildren =
                    (getWindow model.windows parentId).children
            in
            case List.find (\( childApp, _ ) -> childApp == app) parentChildren of
                Just ( _, childId ) ->
                    OS.Bus.FocusApp childId

                Nothing ->
                    openAction

        Nothing ->
            openAction


registerApp :
    Model
    -> Universe
    -> App.Manifest
    -> AppID
    -> WindowConfig
    -> Maybe ParentInfo
    -> Model
registerApp model universe app appId windowConfig parentInfo =
    let
        window =
            createWindow model universe app appId windowConfig parentInfo

        newWindows =
            Dict.insert appId window model.windows
                |> maybeInsertParentChildren window parentInfo

        newNextAppId =
            model.nextAppId + 1

        newNextZIndex =
            model.nextZIndex + 1

        newFocusedWindow =
            Just appId
    in
    { model
        | windows = newWindows
        , nextAppId = newNextAppId
        , nextZIndex = newNextZIndex
        , focusedWindow = newFocusedWindow
    }


deregisterApp : Model -> AppID -> Model
deregisterApp model appId =
    let
        window =
            getWindow model.windows appId

        newWindows =
            Dict.remove appId model.windows
                |> maybeRemoveParentChild window

        newDragging =
            case model.dragging of
                Just ( draggingId, a, b ) ->
                    if draggingId == appId then
                        Nothing

                    else
                        Just ( draggingId, a, b )

                Nothing ->
                    Nothing

        newFocusedWindow =
            case model.focusedWindow of
                Just focusedId ->
                    if focusedId == appId then
                        Nothing

                    else
                        Just focusedId

                Nothing ->
                    Nothing
    in
    { model | windows = newWindows, dragging = newDragging, focusedWindow = newFocusedWindow }


focusApp : Model -> AppID -> Model
focusApp model appId =
    case getWindowSafe model.windows appId of
        Just window ->
            doFocusApp model window False

        Nothing ->
            model



-- TODO: Can be merged to `focusApp`


focusVibrateApp : Model -> AppID -> Model
focusVibrateApp model appId =
    case getWindowSafe model.windows appId of
        Just window ->
            doFocusApp model window True

        Nothing ->
            model


doFocusApp : Model -> Window -> Bool -> Model
doFocusApp model window isVibrating =
    let
        newFocusedWindow =
            Just window.appId

        newWindow =
            { window
                | zIndex = model.nextZIndex
                , isVibrating = isVibrating
            }

        newWindows =
            Dict.insert window.appId newWindow model.windows

        newNextZIndex =
            model.nextZIndex + 1
    in
    { model
        | focusedWindow = newFocusedWindow
        , windows = newWindows
        , nextZIndex = newNextZIndex
    }


unvibrateApp : Model -> AppID -> Model
unvibrateApp model appId =
    case getWindowSafe model.windows appId of
        Just window ->
            doUnvibrateApp model window

        Nothing ->
            model


doUnvibrateApp : Model -> Window -> Model
doUnvibrateApp model window =
    let
        newWindows =
            Dict.insert window.appId { window | isVibrating = False } model.windows
    in
    { model | windows = newWindows }



-- popup
-- Model > Misc


dummyWindow : Window
dummyWindow =
    { appId = 0
    , app = App.InvalidApp
    , posX = 0
    , posY = 0
    , lenX = 100
    , lenY = 100
    , isVisible = True
    , isVibrating = False
    , title = ""
    , zIndex = 999
    , parent = Nothing
    , isPopup = False
    , children = []
    , blockedByApp = Nothing
    , childBehavior = Nothing
    , universe = Universe.Singleplayer
    , sessionID = SessionID (ServerID.fromValue 0)
    }


dummyWindowConfig : WindowConfig
dummyWindowConfig =
    { lenX = 0
    , lenY = 0
    , title = ""
    , childBehavior = Nothing
    , misc = Nothing
    }
