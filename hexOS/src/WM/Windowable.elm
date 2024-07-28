module WM.Windowable exposing (..)

-- Maybe rename to OS.dispatcher? or something like that

import Apps.Demo as Demo
import Apps.Manifest as App
import Apps.Popups.ConfirmationDialog as ConfirmationDialog
import Apps.Popups.DemoSingleton as DemoSingleton
import Apps.Types as Apps
import OS.AppID exposing (AppID)
import OS.Bus
import Utils
import WM



-------
-- app


willOpen : App.Manifest -> WM.WindowInfo -> OS.Bus.Action
willOpen app windowInfo =
    case app of
        App.InvalidApp ->
            OS.Bus.NoOp

        App.DemoApp ->
            Demo.willOpen windowInfo

        App.PopupConfirmationDialog ->
            ConfirmationDialog.willOpen windowInfo

        App.PopupDemoSingleton ->
            DemoSingleton.willOpen windowInfo


willOpenChild :
    App.Manifest
    -> Apps.Model
    -> WM.Window
    -> WM.WindowInfo
    -> OS.Bus.Action
willOpenChild child parentModel parentWindow childWindowInfo =
    case parentModel of
        Apps.InvalidModel ->
            OS.Bus.NoOp

        Apps.DemoModel model ->
            Demo.willOpenChild model child parentWindow childWindowInfo

        _ ->
            OS.Bus.NoOp


didOpen :
    App.Manifest
    -> AppID
    -> WM.WindowInfo
    -> ( Apps.Model, Cmd Apps.Msg )
didOpen app appId windowInfo =
    let
        wrapMe appModel appMsg didOpenFn =
            let
                ( iModel, iCmd ) =
                    didOpenFn windowInfo
            in
            ( appModel iModel, Cmd.map (appMsg appId) iCmd )
    in
    case app of
        App.InvalidApp ->
            ( Apps.InvalidModel
            , Utils.msgToCmd Apps.InvalidMsg
            )

        App.DemoApp ->
            wrapMe
                Apps.DemoModel
                Apps.DemoMsg
                Demo.didOpen

        App.PopupConfirmationDialog ->
            wrapMe
                Apps.PopupConfirmationDialogModel
                Apps.PopupConfirmationDialogMsg
                ConfirmationDialog.didOpen

        App.PopupDemoSingleton ->
            wrapMe
                Apps.PopupDemoSingletonModel
                Apps.PopupDemoSingletonMsg
                DemoSingleton.didOpen


didOpenChild :
    AppID
    -> Apps.Model
    -> ( App.Manifest, AppID )
    -> WM.WindowInfo
    -> ( Apps.Model, Cmd Apps.Msg, OS.Bus.Action )
didOpenChild parentId parentModel childInfo windowInfo =
    let
        wrapMe toAppModel toAppMsg didOpenChildFn =
            let
                ( iModel, iCmd, action ) =
                    didOpenChildFn childInfo windowInfo
            in
            ( toAppModel iModel, Cmd.map (toAppMsg parentId) iCmd, action )
    in
    case parentModel of
        Apps.InvalidModel ->
            ( Apps.InvalidModel, Cmd.none, OS.Bus.NoOp )

        Apps.DemoModel model ->
            wrapMe
                Apps.DemoModel
                Apps.DemoMsg
                (Demo.didOpenChild model)

        -- Default. All patterns below could be a catch-all, but we need to have an
        -- "extractModel" function for the first parameter
        Apps.PopupConfirmationDialogModel model ->
            ( Apps.PopupConfirmationDialogModel model, Cmd.none, OS.Bus.NoOp )

        Apps.PopupDemoSingletonModel model ->
            ( Apps.PopupDemoSingletonModel model, Cmd.none, OS.Bus.NoOp )


willClose : WM.Window -> Apps.Model -> OS.Bus.Action
willClose window appModel =
    case appModel of
        Apps.InvalidModel ->
            OS.Bus.NoOp

        Apps.DemoModel model ->
            Demo.willClose window.appId model window

        -- Popups
        Apps.PopupConfirmationDialogModel model ->
            ConfirmationDialog.willClose window.appId model window

        Apps.PopupDemoSingletonModel model ->
            DemoSingleton.willClose window.appId model window


didCloseChild :
    AppID
    -> Apps.Model
    -> ( App.Manifest, AppID )
    -> WM.Window
    -> ( Apps.Model, Cmd Apps.Msg, OS.Bus.Action )
didCloseChild parentId parentModel childInfo parentWindow =
    let
        wrapMe toAppModel toAppMsg didCloseChildFn =
            let
                ( iModel, iCmd, action ) =
                    didCloseChildFn childInfo parentWindow
            in
            ( toAppModel iModel, Cmd.map (toAppMsg parentId) iCmd, action )
    in
    case parentModel of
        Apps.InvalidModel ->
            ( Apps.InvalidModel, Cmd.none, OS.Bus.NoOp )

        Apps.DemoModel model ->
            wrapMe
                Apps.DemoModel
                Apps.DemoMsg
                (Demo.didCloseChild model)

        -- Default. All patterns below could be a catch-all, but we need to have an
        -- "extractModel" function for the first parameter
        Apps.PopupConfirmationDialogModel model ->
            ( Apps.PopupConfirmationDialogModel model, Cmd.none, OS.Bus.NoOp )

        Apps.PopupDemoSingletonModel model ->
            ( Apps.PopupDemoSingletonModel model, Cmd.none, OS.Bus.NoOp )


willFocus : App.Manifest -> AppID -> WM.Window -> OS.Bus.Action
willFocus app appId window =
    case app of
        App.InvalidApp ->
            OS.Bus.NoOp

        App.DemoApp ->
            Demo.willFocus appId window

        -- Popups
        App.PopupConfirmationDialog ->
            ConfirmationDialog.willFocus appId window

        App.PopupDemoSingleton ->
            DemoSingleton.willFocus appId window


getWindowConfig : WM.WindowInfo -> WM.WindowConfig
getWindowConfig windowInfo =
    case windowInfo.app of
        App.InvalidApp ->
            WM.dummyWindowConfig

        App.DemoApp ->
            Demo.getWindowConfig windowInfo

        App.PopupConfirmationDialog ->
            ConfirmationDialog.getWindowConfig windowInfo

        App.PopupDemoSingleton ->
            DemoSingleton.getWindowConfig windowInfo