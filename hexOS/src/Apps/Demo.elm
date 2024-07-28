module Apps.Demo exposing (..)

import Apps.Manifest as App
import Apps.Popups.ConfirmationDialog as ConfirmationDialog
import OS.AppID exposing (AppID)
import OS.Bus
import UI exposing (UI, cl, col, id, row, text)
import UI.Button
import UI.Icon
import Utils
import WM


type Msg
    = IncrementCount
    | DecrementCount
    | OpenBlockingPopup
    | OpenSingletonPopup
    | ToOS OS.Bus.Action
    | FromConfirmationDialog AppID ConfirmationDialog.Action


type alias Model =
    { appId : AppID
    , count : Int
    }



-- View


view : Model -> UI Msg
view model =
    UI.col [ cl "app-demo" ]
        [ viewLaunchers model
        , viewCounter model
        ]


viewLaunchers : Model -> UI Msg
viewLaunchers model =
    UI.col []
        [ UI.Icon.iAdd (Just "Open Contact")
            |> UI.Button.fromIcon
            |> UI.Button.toUI
        , UI.Icon.iAdd (Just "Open Blocking Popup")
            |> UI.Button.fromIcon
            |> UI.Button.withOnClick OpenBlockingPopup
            |> UI.Button.toUI
        , UI.Icon.iAdd (Just "Open Singleton Popup")
            |> UI.Button.fromIcon
            |> UI.Button.withOnClick OpenSingletonPopup
            |> UI.Button.toUI
        ]


viewCounter : Model -> UI Msg
viewCounter model =
    UI.col []
        [ text ("Count: " ++ String.fromInt model.count)
        , row [ cl "app-demo-counter-actions" ]
            [ UI.Icon.iAdd Nothing
                |> UI.Button.fromIcon
                |> UI.Button.withClass "app-demo-counter-inc"
                |> UI.Button.withOnClick IncrementCount
                |> UI.Button.toUI
            , UI.Icon.iRemove Nothing
                |> UI.Button.fromIcon
                |> UI.Button.withOnClick DecrementCount
                |> UI.Button.toUI
            ]
        ]



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        IncrementCount ->
            ( { model | count = model.count + 1 }, Cmd.none )

        DecrementCount ->
            ( { model | count = model.count - 1 }, Cmd.none )

        -- TODO: Maybe change update signature to be (model, Cmd Msg, [ OS.Bus.Action ])?
        OpenBlockingPopup ->
            ( model
            , Utils.msgToCmd
                (ToOS <|
                    OS.Bus.RequestOpenApp
                        App.PopupConfirmationDialog
                        (Just ( App.DemoApp, model.appId ))
                )
            )

        OpenSingletonPopup ->
            ( model
            , Utils.msgToCmd
                (ToOS <|
                    OS.Bus.RequestOpenApp
                        App.PopupDemoSingleton
                        (Just ( App.DemoApp, model.appId ))
                )
            )

        ToOS bus ->
            ( model, Cmd.none )

        FromConfirmationDialog _ _ ->
            ( model, Cmd.none )



-- OS.Dispatcher callbacks


getWindowConfig : WM.WindowInfo -> WM.WindowConfig
getWindowConfig _ =
    { lenX = 800
    , lenY = 600
    , title = "DemoApp"
    , childBehavior = Nothing
    , misc = Nothing
    }


willOpen : WM.WindowInfo -> OS.Bus.Action
willOpen window =
    OS.Bus.OpenApp App.DemoApp Nothing


didOpen : WM.WindowInfo -> ( Model, Cmd Msg )
didOpen { appId } =
    ( { appId = appId, count = 0 }
    , Cmd.none
    )



-- TODO: Implement didClose and, on close, close all singleton popups of one type but not the other


willClose : AppID -> Model -> WM.Window -> OS.Bus.Action
willClose appId _ _ =
    OS.Bus.CloseApp appId


willFocus : AppID -> WM.Window -> OS.Bus.Action
willFocus appId window =
    OS.Bus.FocusApp appId



-- Children
-- TODO: Singleton logic can (and probably should) be delegated to the OS/WM


willOpenChild : Model -> App.Manifest -> WM.Window -> WM.WindowInfo -> OS.Bus.Action
willOpenChild model child parentWindow _ =
    OS.Bus.OpenApp child <| Just ( App.DemoApp, parentWindow.appId )


didOpenChild :
    Model
    -> ( App.Manifest, AppID )
    -> WM.WindowInfo
    -> ( Model, Cmd Msg, OS.Bus.Action )
didOpenChild model _ _ =
    ( model, Cmd.none, OS.Bus.NoOp )


didCloseChild :
    Model
    -> ( App.Manifest, AppID )
    -> WM.Window
    -> ( Model, Cmd Msg, OS.Bus.Action )
didCloseChild model _ _ =
    -- TODO: Make defaults for these
    ( model, Cmd.none, OS.Bus.NoOp )
