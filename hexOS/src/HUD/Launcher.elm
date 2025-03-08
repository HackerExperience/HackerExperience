module HUD.Launcher exposing
    ( Model
    , Msg(..)
    , addGlobalEvents
    , initialModel
    , update
    , view
    )

import Apps.Manifest as App
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
    { isOpen : Bool }


type Msg
    = ToOS OS.Bus.Action
    | OpenLauncherOverlay
    | CloseLauncherOverlay
    | LaunchApp App.Manifest
    | CtxMenuMsg (CtxMenu.Msg Menu)
    | NoOp


type Menu
    = NoMenu



-- Model


initialModel : Model
initialModel =
    { isOpen = False }



-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        OpenLauncherOverlay ->
            ( { model | isOpen = True }, Effect.domFocus "hud-lo-search-input" NoOp )

        CloseLauncherOverlay ->
            ( { model | isOpen = False }, Effect.none )

        LaunchApp app ->
            ( { model | isOpen = False }
            , Effect.msgToCmd <| ToOS <| OS.Bus.RequestOpenApp app Nothing
            )

        CtxMenuMsg _ ->
            ( model, Effect.none )

        NoOp ->
            ( model, Effect.none )

        ToOS _ ->
            -- Handled by parent
            ( model, Effect.none )



-- View


view : Model -> UI Msg
view model =
    row (id "hud-launcher" :: addEvents model)
        [ viewLauncher model
        , if model.isOpen then
            viewOverlay

          else
            UI.emptyEl
        ]


addEvents : Model -> List (UI.Attribute Msg)
addEvents model =
    [ HA.map CtxMenuMsg CtxMenu.noop ]


viewLauncher : Model -> UI Msg
viewLauncher { isOpen } =
    let
        onClickMsg =
            if isOpen then
                NoOp

            else
                OpenLauncherOverlay

        icon =
            UI.Icon.msOutline "apps" Nothing
                |> UI.Icon.withOnClick onClickMsg
                |> UI.Icon.toUI

        iconArea =
            row [ cl "hud-l-launcher-icon-area" ]
                [ icon ]
    in
    row [ cl "hud-l-launcher-area" ]
        [ iconArea ]


viewOverlay : UI Msg
viewOverlay =
    row [ id "hud-launcher-overlay" ]
        [ col [ cl "hud-lo-area", stopPropagation "click" ]
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
    row [ cl "hud-lo-search-area" ]
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



-- TODO: stopPropagation should be a util (also used in OS and HUD.CI)


stopPropagation : String -> UI.Attribute Msg
stopPropagation event =
    HE.stopPropagationOn event
        (JD.succeed <| (\msg -> ( msg, True )) NoOp)


addGlobalEvents : Model -> List (UI.Attribute Msg)
addGlobalEvents model =
    if model.isOpen then
        [ HE.on "click" <| JD.succeed CloseLauncherOverlay ]

    else
        []
