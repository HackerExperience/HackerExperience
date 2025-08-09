module Apps.AppStore exposing (..)

import API.Game as GameAPI
import API.Types
import Apps.Input as App
import Apps.Manifest as App
import Effect exposing (Effect)
import Game
import Game.Bus as Game
import Game.Model.File exposing (Files)
import Game.Model.Installation exposing (Installations)
import Game.Model.NIP as NIP
import Game.Model.ProcessOperation as Operation
import Game.Model.ServerID as ServerID exposing (ServerID)
import Game.Model.Software as Software exposing (Manifest, Software)
import Game.Model.SoftwareType as SoftwareType exposing (SoftwareType)
import List.Extra as List
import Maybe.Extra as Maybe
import OS.AppID exposing (AppID)
import OS.Bus
import OS.CtxMenu
import OS.CtxMenu.Menus as CtxMenu
import UI exposing (UI, cl, clIf, col, div, row, text)
import UI.Icon
import WM


type Msg
    = ToOS OS.Bus.Action
    | ToCtxMenu OS.CtxMenu.Msg
    | SelectTab Tab
    | OpenAppDetails SoftwareType
    | DownloadSoftware SoftwareType
    | OnAppStoreInstallResponse SoftwareType API.Types.AppStoreInstallResult


type Tab
    = TabApps (Maybe SoftwareType)
    | TabInstallations


type alias Model =
    { appId : AppID
    , serverId : ServerID
    , tab : Tab
    }



-- Model


getTabName : Tab -> String
getTabName tab =
    case tab of
        TabApps _ ->
            "Apps"

        TabInstallations ->
            "Installations"



-- Update


update : Game.Model -> Msg -> Model -> ( Model, Effect Msg )
update game msg model =
    case msg of
        SelectTab tab ->
            ( { model | tab = tab }, Effect.none )

        OpenAppDetails type_ ->
            ( { model | tab = TabApps (Just type_) }, Effect.none )

        DownloadSoftware softwareType ->
            let
                config =
                    GameAPI.appStoreInstallConfig
                        game.apiCtx
                        model.serverId
                        softwareType

                toGameMsg =
                    Game.ProcessOperation
                        -- TODO: This `invalidNip` call is here as a temporary placeholder.
                        -- Refactor the Msg so the NIP is made optional.
                        NIP.invalidNip
                        (Operation.Starting <| Operation.AppStoreInstall softwareType)
            in
            ( model
            , Effect.batch
                [ Effect.appStoreInstall (OnAppStoreInstallResponse softwareType) config
                , Effect.msgToCmd <| ToOS <| OS.Bus.ToGame toGameMsg
                ]
            )

        OnAppStoreInstallResponse _ _ ->
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
    row [ cl "app-appstore" ]
        [ viewSideBar model
        , vBody model game
        ]



-- View > Body


vBody : Model -> Game.Model -> UI Msg
vBody model game =
    let
        body =
            case model.tab of
                TabApps Nothing ->
                    vBodyAppsIndex model game

                TabApps (Just type_) ->
                    vBodyAppsDetail model game type_

                TabInstallations ->
                    vBodyInstallations model
    in
    col [ cl "a-ast-body" ]
        [ body ]



-- View > Tab: "Apps"


vBodyAppsIndex : Model -> Game.Model -> UI Msg
vBodyAppsIndex model game =
    let
        server =
            Game.getServerById game model.serverId

        apps =
            renderAppsEntries game.manifest server.files server.installations
    in
    row [ cl "a-ast-apps-index" ] apps


renderAppsEntries : Manifest -> Files -> Installations -> List (UI Msg)
renderAppsEntries manifest files installations =
    let
        appStoreSoftware =
            Software.listAppStoreSoftware manifest

        appStoreInstallableSoftware =
            Software.getAppStoreInstallableSoftware appStoreSoftware files installations
    in
    List.foldl (renderAppsEntry appStoreInstallableSoftware) [] appStoreSoftware


renderAppsEntry : List SoftwareType -> Software -> List (UI Msg) -> List (UI Msg)
renderAppsEntry installableSoftware software acc =
    let
        name =
            SoftwareType.typeToName software.type_

        isInstallable =
            List.find (\type_ -> type_ == software.type_) installableSoftware
                |> Maybe.isJust

        icon =
            UI.Icon.msOutline (SoftwareType.typeToIcon software.type_) Nothing
                |> UI.Icon.withClass "a-ast-apps-idx-entry-icon"
                |> UI.Icon.toUI

        entry =
            col
                [ cl "a-ast-apps-idx-entry"
                , UI.onClick (OpenAppDetails software.type_)
                ]
                [ icon
                , text name
                , renderAppEntryOverlay isInstallable software
                ]
    in
    entry :: acc


renderAppEntryOverlay : Bool -> Software -> UI Msg
renderAppEntryOverlay isInstallable software =
    if Maybe.isJust software.currentOp then
        let
            -- TODO: Ideally this should be a UI.Spinner component
            spinnerIcon =
                UI.Icon.msOutline "progress_activity" Nothing
                    |> UI.Icon.withClass "a-ast-apps-idx-entry-overlay-icon"
                    |> UI.Icon.toUI
        in
        div
            [ cl "a-ast-apps-idx-entry-spinner-overlay" ]
            [ spinnerIcon ]

    else if isInstallable then
        let
            downloadIcon =
                UI.Icon.msOutline "download" Nothing
                    |> UI.Icon.withClass "a-ast-apps-idx-entry-overlay-icon"
                    |> UI.Icon.toUI
        in
        div
            [ cl "a-ast-apps-idx-entry-download-overlay"
            , UI.stopPropagation "click" (DownloadSoftware software.type_)
            ]
            [ downloadIcon ]

    else
        let
            installedIcon =
                UI.Icon.msOutline "check_circle" Nothing
                    |> UI.Icon.withClass "a-ast-apps-idx-entry-overlay-icon"
                    |> UI.Icon.toUI
        in
        div
            [ cl "a-ast-apps-idx-entry-installed-overlay" ]
            [ installedIcon ]


vBodyAppsDetail : Model -> Game.Model -> SoftwareType -> UI Msg
vBodyAppsDetail model game type_ =
    let
        backIcon =
            UI.Icon.msOutline "arrow_back" Nothing
                |> UI.Icon.withClass "a-ast-apps-dtl-hdr-backicon"
                |> UI.Icon.toUI

        backEl =
            div [ UI.onClick (SelectTab <| TabApps Nothing) ]
                [ backIcon ]

        header =
            row [ cl "a-ast-apps-dtl-header" ]
                [ backEl
                , text "App Details"
                ]
    in
    col [ cl "a-ast-apps-details" ]
        [ header
        , renderAppDetailBody model game type_
        ]


renderAppDetailBody : Model -> Game.Model -> SoftwareType -> UI Msg
renderAppDetailBody model game softwareType =
    let
        server =
            Game.getServerById game model.serverId

        appStoreSoftware =
            Software.listAppStoreSoftware game.manifest
                -- This filtering is a premature optimization to make sure we don't iterate over
                -- irrelevant software types. We only care about `softwareType` in this context.
                |> List.filter (\{ type_ } -> type_ == softwareType)

        installableSoftware =
            Software.getAppStoreInstallableSoftware
                appStoreSoftware
                server.files
                server.installations

        isInstallable =
            List.find (\type_ -> type_ == softwareType) installableSoftware
                |> Maybe.isJust
    in
    col [ cl "a-ast-apps-dtl-body" ]
        [ text (SoftwareType.typeToString softwareType)
        , text "What? Were you expecting more information? Come back later (:"
        , if isInstallable then
            -- TODO: Turn this into a functional button once the UI is ironed out
            text "Click here to install (just kidding)"

          else
            text "Already installed"
        ]



-- View > Tab: "Installations"


vBodyInstallations : Model -> UI Msg
vBodyInstallations _ =
    div [] [ text "Installations" ]



-- View > Sidebar


viewSideBar : Model -> UI Msg
viewSideBar model =
    let
        tabs =
            renderTabs model
    in
    col [ cl "a-ast-sidebar" ]
        tabs


renderTabs : Model -> List (UI Msg)
renderTabs model =
    [ renderTab (TabApps Nothing) model.tab
    , renderTab TabInstallations model.tab
    ]


renderTab : Tab -> Tab -> UI Msg
renderTab tab selectedTab =
    let
        isTabSelected =
            case ( tab, selectedTab ) of
                ( TabApps _, TabApps _ ) ->
                    True

                _ ->
                    tab == selectedTab
    in
    row
        [ cl "a-ast-sb-tab"
        , clIf isTabSelected "a-ast-sb-tab-selected"
        , UI.onClickIf (not isTabSelected) <| SelectTab tab
        ]
        [ text <| getTabName tab ]



-- OS.Dispatcher Callbacks


getWindowConfig : WM.WindowInfo -> WM.WindowConfig
getWindowConfig _ =
    { lenX = 800
    , lenY = 500
    , title = "AppStore"
    , childBehavior = Nothing
    , misc = Nothing
    }


willOpen : WM.WindowInfo -> App.InitialInput -> OS.Bus.Action
willOpen _ input =
    OS.Bus.OpenApp App.AppStoreApp Nothing input


didOpen : WM.WindowInfo -> App.InitialInput -> ( Model, Effect Msg )
didOpen { appId, sessionId } _ =
    let
        serverId =
            WM.getSessionServerID sessionId
                |> Maybe.withDefault (ServerID.fromValue "invalid")
    in
    ( { appId = appId
      , serverId = serverId
      , tab = TabApps Nothing
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
