module HUD exposing
    ( Model
    , Msg(..)
    , initialModel
    , onWindowClose
    , onWindowCollapse
    , subscriptions
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
    , launcher : Launcher.Model
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
    , launcher = Launcher.initialModel
    , sysTray = 0
    }


onWindowClose : Model -> Model
onWindowClose model =
    { model | ci = CI.onWindowClose model.ci }


onWindowCollapse : Model -> Model
onWindowCollapse model =
    { model | ci = CI.onWindowCollapse model.ci }



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

        DockMsg _ ->
            -- let
            --     ( newCiModel, effect ) =
            --         CI.update state ciMsg model.ci
            -- in
            ( model, Effect.none )

        LauncherMsg launcherMsg ->
            let
                ( newLauncherModel, effect ) =
                    Launcher.update launcherMsg model.launcher
            in
            ( { model | launcher = newLauncherModel }, Effect.map LauncherMsg effect )

        SysTrayMsg _ ->
            -- let
            --     ( newCiModel, effect ) =
            --         CI.update state ciMsg model.ci
            -- in
            ( model, Effect.none )

        ToOS _ ->
            -- Handled by parent
            ( model, Effect.none )



-- View


view : State -> Model -> WM.Model -> UI Msg
view state model wm =
    row [ id "hud" ]
        [ Html.map CIMsg <| CI.view state model.ci
        , Html.map LauncherMsg <| Launcher.view model.launcher
        , Html.map DockMsg <| Dock.view state wm
        , Html.map SysTrayMsg <| SysTray.view state
        ]



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map CIMsg <| CI.subscriptions model.ci
        , Sub.map LauncherMsg <| Launcher.subscriptions model.launcher
        ]
