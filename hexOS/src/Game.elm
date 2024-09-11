module Game exposing (..)

import OS
import UI exposing (UI)
import Game.Universe



-- Types


type Msg
    = NoOp


type alias Model =
    { mp : Game.Universe.Model
    , os : OS.Model
    }



-- Model


init : Game.Universe.Model -> OS.Model -> ( Model, Cmd Msg )
init mpModel osModel =
    ( { mp = mpModel
      , os = osModel
      }
    , Cmd.none
    )



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )



-- View


documentView : Model -> UI.Document Msg
documentView model =
    { title = "Hacker Experience (play)", body = view model }


view : Model -> List (UI Msg)
view model =
    []
