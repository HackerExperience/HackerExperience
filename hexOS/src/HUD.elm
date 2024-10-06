module HUD exposing
    ( Model
    , Msg
    , initialModel
    , update
    , view
    )

import Effect exposing (Effect)
import Game exposing (State)
import Game.Universe as Universe
import HUD.ConnectionInfo as CI
import Html
import UI exposing (UI, cl, col, div, id, row, style, text)



-- Types


type alias Model =
    { ci : CI.Model }


type Msg
    = CIMsg CI.Msg



-- Model


initialModel : Model
initialModel =
    { ci = CI.initialModel }



-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        CIMsg ciMsg ->
            let
                ( newCiModel, effect ) =
                    CI.update ciMsg model.ci
            in
            ( { model | ci = newCiModel }, Effect.map CIMsg effect )



-- View


view : Game.State -> UI Msg
view state =
    row [ id "hud" ]
        [ Html.map CIMsg <| CI.view state ]
