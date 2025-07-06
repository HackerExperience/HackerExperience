module Apps.AppStore exposing (..)

import API.Game as GameAPI
import API.Types
import Apps.Input as App
import Apps.Manifest as App
import Effect exposing (Effect)
import Game
import Game.Model.ServerID as ServerID exposing (ServerID)
import Game.Model.Software as Software exposing (Manifest, Software)
import Game.Model.SoftwareType as SoftwareType exposing (SoftwareType)
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
            in
            ( model
            , Effect.batch
                [ Effect.appStoreInstall (OnAppStoreInstallResponse softwareType) config
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
                    vBodyAppsDetail model type_

                TabInstallations ->
                    vBodyInstallations model
    in
    col [ cl "a-ast-body" ]
        [ body ]



-- View > Tab: "Apps"


vBodyAppsIndex : Model -> Game.Model -> UI Msg
vBodyAppsIndex _ game =
    let
        apps =
            renderAppsEntries game.manifest
    in
    row [ cl "a-ast-apps-index" ] apps


renderAppsEntries : Manifest -> List (UI Msg)
renderAppsEntries manifest =
    let
        appStoreSoftware =
            Software.listAppStoreSoftware manifest
    in
    List.foldl renderAppsEntry [] appStoreSoftware


renderAppsEntry : Software -> List (UI Msg) -> List (UI Msg)
renderAppsEntry software acc =
    let
        name =
            SoftwareType.typeToName software.type_

        icon =
            UI.Icon.msOutline (SoftwareType.typeToIcon software.type_) Nothing
                |> UI.Icon.withClass "a-ast-apps-idx-entry-icon"
                |> UI.Icon.toUI

        downloadIcon =
            UI.Icon.msOutline "download" Nothing
                |> UI.Icon.withClass "a-ast-apps-idx-entry-overlay-icon"
                |> UI.Icon.toUI

        downloadOverlay =
            div
                [ cl "a-ast-apps-idx-entry-overlay"
                , UI.stopPropagation "click" (DownloadSoftware software.type_)
                ]
                [ downloadIcon ]

        entry =
            col
                [ cl "a-ast-apps-idx-entry"
                , UI.onClick (OpenAppDetails software.type_)
                ]
                [ icon
                , text name
                , downloadOverlay
                ]
    in
    entry :: acc


vBodyAppsDetail : Model -> SoftwareType -> UI Msg
vBodyAppsDetail _ type_ =
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
        , renderAppDetailBody type_
        ]


renderAppDetailBody : SoftwareType -> UI Msg
renderAppDetailBody type_ =
    col [ cl "a-ast-apps-dtl-body" ]
        [ text (SoftwareType.typeToString type_)
        , text "What? Were you expecting more information? Come back later (:"
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
