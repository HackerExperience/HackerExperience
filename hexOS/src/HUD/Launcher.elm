module HUD.Launcher exposing
    ( Model
    , Msg(..)
    , initialModel
    , subscriptions
    , update
    , view
    )

import Apps.Manifest as App
import Browser.Events
import Effect exposing (Effect)
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as JD
import OS.Bus
import OS.CtxMenu as CtxMenu
import UI exposing (UI, cl, col, id, row, text)
import UI.Icon
import UI.Model.FormFields as FormFields
import UI.TextInput



-- Types


type alias Model =
    { isOpen : Bool
    , isLauncherHovered : Bool
    , isOverlayHovered : Bool
    }


type Msg
    = ToOS OS.Bus.Action
    | ToCtxMenu CtxMenu.Msg
    | OpenLauncherOverlay
    | CloseLauncherOverlay
    | OnLauncherEnter
    | OnLauncherLeave
    | OnOverlayEnter
    | OnOverlayLeave
    | LaunchApp App.Manifest
    | NoOp



-- Model


initialModel : Model
initialModel =
    { isOpen = False
    , isLauncherHovered = False
    , isOverlayHovered = False
    }



-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        OpenLauncherOverlay ->
            ( { model | isOpen = True }, Effect.domFocus "hud-lo-search-input" NoOp )

        CloseLauncherOverlay ->
            ( { model | isOpen = False, isOverlayHovered = False }, Effect.none )

        OnLauncherEnter ->
            ( { model | isLauncherHovered = True }, Effect.none )

        OnLauncherLeave ->
            ( { model | isLauncherHovered = False }, Effect.none )

        OnOverlayEnter ->
            ( { model | isOverlayHovered = True }, Effect.none )

        OnOverlayLeave ->
            ( { model | isOverlayHovered = False }, Effect.none )

        LaunchApp app ->
            ( { model | isOpen = False }
            , Effect.msgToCmd <| ToOS <| OS.Bus.RequestOpenApp app Nothing
            )

        NoOp ->
            ( model, Effect.none )

        ToOS _ ->
            -- Handled by OS
            ( model, Effect.none )

        ToCtxMenu _ ->
            -- Handled by OS
            ( model, Effect.none )



-- View


view : Model -> UI Msg
view model =
    row
        [ id "hud-launcher"
        , HA.map ToCtxMenu CtxMenu.noop
        ]
        [ viewLauncher model
        , if model.isOpen then
            viewOverlay

          else
            UI.emptyEl
        ]


viewLauncher : Model -> UI Msg
viewLauncher { isOpen } =
    let
        onClickMsg =
            if isOpen then
                CloseLauncherOverlay

            else
                OpenLauncherOverlay

        icon =
            UI.Icon.msOutline "apps" Nothing
                |> UI.Icon.toUI

        iconArea =
            row
                [ cl "hud-l-launcher-icon-area"
                , UI.onClick onClickMsg
                , HE.onMouseEnter OnLauncherEnter
                , HE.onMouseLeave OnLauncherLeave
                ]
                [ icon ]
    in
    row [ cl "hud-l-launcher-area" ]
        [ iconArea ]


viewOverlay : UI Msg
viewOverlay =
    row [ id "hud-launcher-overlay" ]
        [ col
            [ cl "hud-lo-area"
            , HE.onMouseEnter OnOverlayEnter
            , HE.onMouseLeave OnOverlayLeave
            ]
            [ viewOverlaySearch
            , viewOverlayApps
            ]
        ]


viewOverlaySearch : UI Msg
viewOverlaySearch =
    let
        formValue =
            FormFields.textWithValue ""

        textInput =
            UI.Icon.msOutline "search" Nothing
                |> UI.TextInput.fromIcon formValue
                |> UI.TextInput.withID "hud-lo-search-input"
                |> UI.TextInput.toUI
    in
    row
        [ cl "hud-lo-search-area"
        ]
        [ textInput ]


viewOverlayApps : UI Msg
viewOverlayApps =
    let
        launchableApps =
            [ App.LogViewerApp
            , App.RemoteAccessApp
            , App.DemoApp
            ]

        appEntries =
            List.foldr renderOverlayAppEntries [] launchableApps
    in
    row [ cl "hud-lo-apps-area" ]
        appEntries


renderOverlayAppEntries : App.Manifest -> List (UI Msg) -> List (UI Msg)
renderOverlayAppEntries app acc =
    viewOverlayAppEntry app :: acc


viewOverlayAppEntry : App.Manifest -> UI Msg
viewOverlayAppEntry app =
    let
        ( name, iconName ) =
            ( App.getName app, App.getIcon app )

        icon =
            UI.Icon.msOutline iconName Nothing
                |> UI.Icon.toUI

        entryIconArea =
            row [ cl "hud-lo-apps-entry-icon-area" ]
                [ icon ]

        entryNameArea =
            row [ cl "hud-lo-apps-entry-name-area" ]
                [ text name ]
    in
    col [ cl "hud-lo-apps-entry", UI.onClick (LaunchApp app) ]
        [ entryIconArea
        , entryNameArea
        ]



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.isOpen && not model.isOverlayHovered && not model.isLauncherHovered then
        Browser.Events.onMouseDown (JD.succeed CloseLauncherOverlay)

    else
        Sub.none
