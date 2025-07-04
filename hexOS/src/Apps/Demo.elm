module Apps.Demo exposing (..)

import Apps.Input as App
import Apps.Manifest as App
import Effect exposing (Effect)
import Game
import OS.AppID exposing (AppID)
import OS.Bus
import UI exposing (UI, cl, row, text)
import UI.Button
import UI.Icon
import WM


type Msg
    = IncrementCount
    | DecrementCount
    | OpenBlockingPopup
    | OpenSingletonPopup
    | ToOS OS.Bus.Action


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
viewLaunchers _ =
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


update : Game.Model -> Msg -> Model -> ( Model, Effect Msg )
update _ msg model =
    case msg of
        IncrementCount ->
            ( { model | count = model.count + 1 }, Effect.none )

        DecrementCount ->
            ( { model | count = model.count - 1 }, Effect.none )

        -- TODO: Maybe change update signature to be (model, Effect Msg, [ OS.Bus.Action ])?
        OpenBlockingPopup ->
            ( model
            , Effect.msgToCmd
                (ToOS <|
                    OS.Bus.RequestOpenApp
                        App.PopupConfirmationPrompt
                        (Just ( App.DemoApp, model.appId ))
                        App.EmptyInput
                )
            )

        OpenSingletonPopup ->
            ( model
            , Effect.msgToCmd
                (ToOS <|
                    OS.Bus.RequestOpenApp
                        App.PopupDemoSingleton
                        (Just ( App.DemoApp, model.appId ))
                        App.EmptyInput
                )
            )

        ToOS _ ->
            ( model, Effect.none )



-- OS.Dispatcher callbacks


getWindowConfig : WM.WindowInfo -> WM.WindowConfig
getWindowConfig _ =
    { lenX = 800
    , lenY = 600
    , title = "DemoApp"
    , childBehavior = Nothing
    , misc = Nothing
    }


willOpen : WM.WindowInfo -> App.InitialInput -> OS.Bus.Action
willOpen _ input =
    OS.Bus.OpenApp App.DemoApp Nothing input


didOpen : WM.WindowInfo -> App.InitialInput -> ( Model, Effect Msg )
didOpen { appId } _ =
    ( { appId = appId, count = 0 }
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
    OS.Bus.OpenApp child (Just ( App.DemoApp, parentWindow.appId )) input


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
