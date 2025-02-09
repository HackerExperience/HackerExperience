module HUD exposing
    ( Model
    , Msg(..)
    , addGlobalEvents
    , initialModel
    , update
    , view
    )

import Effect exposing (Effect)
import HUD.ConnectionInfo as CI
import HUD.Dock as Dock
import HUD.Launcher as Launcher
import HUD.SysTray as SysTray
import Html
import Html.Attributes as HA
import OS.Bus
import State exposing (State)
import UI exposing (UI, id, row)
import WM



-- Types


type alias Model =
    { ci : CI.Model
    , dock : Int
    , launcher : Int
    , sysTray : Int
    }


type Msg
    = CIMsg CI.Msg
    | DockMsg Dock.Msg
    | LauncherMsg Launcher.Msg
    | SysTrayMsg SysTray.Msg
    | ToOS OS.Bus.Action



-- Model


initialModel : Model
initialModel =
    { ci = CI.initialModel
    , dock = 0
    , launcher = 0
    , sysTray = 0
    }



-- Update


update : State -> Msg -> Model -> ( Model, Effect Msg )
update state msg model =
    case msg of
        CIMsg ciMsg ->
            let
                ( newCiModel, effect ) =
                    CI.update state ciMsg model.ci
            in
            ( { model | ci = newCiModel }, Effect.map CIMsg effect )

        DockMsg dockMsg ->
            -- let
            --     ( newCiModel, effect ) =
            --         CI.update state ciMsg model.ci
            -- in
            ( { model | dock = model.dock }, Effect.none )

        LauncherMsg launcherMsg ->
            -- let
            --     ( newCiModel, effect ) =
            --         CI.update state ciMsg model.ci
            -- in
            ( { model | launcher = model.launcher }, Effect.none )

        SysTrayMsg sysTrayMsg ->
            -- let
            --     ( newCiModel, effect ) =
            --         CI.update state ciMsg model.ci
            -- in
            ( { model | sysTray = model.sysTray }, Effect.none )

        ToOS _ ->
            -- Handled by parent
            ( model, Effect.none )



-- View


view : State -> Model -> WM.Model -> UI Msg
view state model wm =
    row [ id "hud" ]
        [ Html.map CIMsg <| CI.view state model.ci
        , Html.map LauncherMsg <| Launcher.view wm
        , Html.map DockMsg <| Dock.view wm
        , Html.map SysTrayMsg <| SysTray.view state
        ]


addGlobalEvents : Model -> List (UI.Attribute Msg)
addGlobalEvents model =
    List.map (HA.map CIMsg) (CI.addGlobalEvents model.ci)
