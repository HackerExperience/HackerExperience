module Apps.FileExplorer exposing (..)

import API.Game as GameAPI
import API.Types
import Apps.Input as App
import Apps.Manifest as App
import Effect exposing (Effect)
import Game
import Game.Model.File exposing (File)
import Game.Model.FileID exposing (FileID)
import Game.Model.InstallationID exposing (InstallationID)
import Game.Model.NIP exposing (NIP)
import Game.Model.Server as Server
import Game.Model.SoftwareType as SoftwareType
import OS.AppID exposing (AppID)
import OS.Bus
import OS.CtxMenu
import UI exposing (UI, cl, col, row, text)
import UI.Icon
import WM


type Msg
    = ToOS OS.Bus.Action
    | ToCtxMenu OS.CtxMenu.Msg
    | OnDeleteFile FileID
    | OnDeleteFileResponse FileID API.Types.FileDeleteResult
    | OnInstallFile FileID
    | OnInstallFileResponse FileID API.Types.FileInstallResult
    | OnUninstallInstallation InstallationID
    | OnUninstallInstallationResponse InstallationID API.Types.InstallationUninstallResult


type alias Model =
    { appId : AppID
    , nip : NIP
    }



-- Model


filterFiles : Model -> Game.Model -> List File
filterFiles model game =
    -- TODO: Currently this is not doing any filtering other than grabbing all files in the server
    let
        server =
            Game.getServer game model.nip
    in
    Server.listFiles server



-- Update


update : Game.Model -> Msg -> Model -> ( Model, Effect Msg )
update game msg model =
    case msg of
        OnDeleteFile fileId ->
            let
                server =
                    Game.getServer game model.nip

                config =
                    GameAPI.fileDeleteConfig game.apiCtx model.nip fileId server.tunnelId
            in
            ( model
            , Effect.batch
                [ Effect.fileDelete (OnDeleteFileResponse fileId) config
                ]
            )

        OnDeleteFileResponse _ _ ->
            -- Side-effects are handled by the ProcessCreatedEvent
            ( model, Effect.none )

        OnInstallFile fileId ->
            let
                config =
                    GameAPI.fileInstallConfig game.apiCtx model.nip fileId
            in
            ( model
            , Effect.batch
                [ Effect.fileInstall (OnInstallFileResponse fileId) config
                ]
            )

        OnInstallFileResponse _ _ ->
            -- Side-effects are handled by the ProcessCreatedEvent
            ( model, Effect.none )

        OnUninstallInstallation installationId ->
            let
                config =
                    GameAPI.installationUninstallConfig game.apiCtx model.nip installationId
            in
            ( model
            , Effect.batch
                [ Effect.installationUninstall (OnUninstallInstallationResponse installationId) config
                ]
            )

        OnUninstallInstallationResponse _ _ ->
            -- Side-effects are handled by the ProcessCreatedEvent
            ( model, Effect.none )

        ToOS _ ->
            -- Handled by OS
            ( model, Effect.none )

        ToCtxMenu _ ->
            -- Handled by OS
            ( model, Effect.none )



-- View


view : Model -> Game.Model -> OS.CtxMenu.Model -> UI Msg
view model game _ =
    col [ cl "app-file-explorer" ]
        [ vHeader model
        , vBody model game
        ]


vHeader : Model -> UI Msg
vHeader _ =
    row [ cl "a-fex-header" ]
        [ text "Header" ]


vBody : Model -> Game.Model -> UI Msg
vBody model game =
    col [ cl "a-fex-body" ]
        (vFileList model game)


{-| TODO: Lazify
-}
vFileList : Model -> Game.Model -> List (UI Msg)
vFileList model game =
    let
        files =
            filterFiles model game
    in
    List.map (\file -> vFileRow model file) files


vFileRow : Model -> File -> UI Msg
vFileRow _ file =
    let
        iconName =
            SoftwareType.typeToIcon file.type_

        iconNode =
            UI.Icon.msOutline iconName Nothing
                |> UI.Icon.withClass "a-fex-fr-icon"
                |> UI.Icon.toUI

        extensionNode =
            row [ cl "a-fex-fr-extension" ]
                [ text ".crc" ]

        nameNode =
            row [ cl "a-fex-fr-name" ]
                [ text file.name
                , extensionNode
                ]

        versionNode =
            row [ cl "a-fex-fr-version" ]
                [ text "1.0" ]
    in
    row [ cl "a-fex-file-row" ]
        [ iconNode
        , nameNode
        , versionNode
        , vFileRowActions file
        ]


vFileRowActions : File -> UI Msg
vFileRowActions file =
    let
        installOrUninstallAction =
            case file.installationId of
                Just installationId ->
                    UI.Icon.msOutline "stop_circle" Nothing
                        |> UI.Icon.withClass "a-fex-fr-a-entry"
                        |> UI.Icon.withOnClick (OnUninstallInstallation installationId)
                        |> UI.Icon.toUI

                Nothing ->
                    UI.Icon.msOutline "play_circle" Nothing
                        |> UI.Icon.withClass "a-fex-fr-a-entry"
                        |> UI.Icon.withOnClick (OnInstallFile file.id)
                        |> UI.Icon.toUI

        deleteAction =
            UI.Icon.msOutline "delete" Nothing
                |> UI.Icon.withClass "a-fex-fr-a-entry"
                |> UI.Icon.withOnClick (OnDeleteFile file.id)
                |> UI.Icon.toUI

        infoAction =
            UI.Icon.msOutline "info" Nothing
                |> UI.Icon.withClass "a-fex-fr-a-entry"
                |> UI.Icon.toUI
    in
    row [ cl "a-fex-fr-actions" ]
        [ infoAction
        , installOrUninstallAction
        , deleteAction
        ]



-- OS.Dispatcher Callbacks


getWindowConfig : WM.WindowInfo -> WM.WindowConfig
getWindowConfig _ =
    { lenX = 500
    , lenY = 500
    , title = "File Explorer"
    , childBehavior = Nothing
    , misc = Nothing
    }


willOpen : WM.WindowInfo -> App.InitialInput -> OS.Bus.Action
willOpen _ input =
    OS.Bus.OpenApp App.FileExplorerApp Nothing input


didOpen : WM.WindowInfo -> App.InitialInput -> ( Model, Effect Msg )
didOpen { appId, sessionId } _ =
    ( { appId = appId
      , nip = WM.getSessionNIP sessionId
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
