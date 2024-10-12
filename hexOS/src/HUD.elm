module HUD exposing
    ( Model
    , Msg(..)
    , addGlobalEvents
    , initialModel
    , update
    , view
    )

import Effect exposing (Effect)
import Game exposing (State)
import Game.Universe as Universe
import HUD.ConnectionInfo as CI
import Html
import Html.Attributes as HA
import OS.Bus
import UI exposing (UI, cl, col, div, id, row, style, text)



-- Types


type alias Model =
    { ci : CI.Model }


type Msg
    = CIMsg CI.Msg
    | ToOS OS.Bus.Action



-- Model


initialModel : Model
initialModel =
    { ci = CI.initialModel }



-- Update


update : Game.State -> Msg -> Model -> ( Model, Effect Msg )
update state msg model =
    case msg of
        CIMsg ciMsg ->
            let
                ( newCiModel, effect ) =
                    CI.update state ciMsg model.ci
            in
            ( { model | ci = newCiModel }, Effect.map CIMsg effect )

        ToOS _ ->
            -- Handled by parent
            ( model, Effect.none )



-- View


view : Game.State -> Model -> UI Msg
view state model =
    row [ id "hud" ]
        [ Html.map CIMsg <| CI.view state model.ci ]


addGlobalEvents : Model -> List (UI.Attribute Msg)
addGlobalEvents model =
    List.map (HA.map CIMsg) (CI.addGlobalEvents model.ci)
