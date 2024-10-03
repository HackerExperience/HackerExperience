module Game exposing
    ( Model
    , Msg(..)
    , init
      -- , update
    )

import Effect exposing (Effect)
import Game.Universe
import OS



-- Types


type Msg
    = NoOp


type alias Model =
    { mp : Game.Universe.Model
    , os : OS.Model
    }



-- Model


init : Game.Universe.Model -> OS.Model -> ( Model, Effect Msg )
init mpModel osModel =
    ( { mp = mpModel
      , os = osModel
      }
    , Effect.none
    )



-- Update
-- update : Msg -> Model -> ( Model, Effect Msg )
-- update msg model =
--     case msg of
--         NoOp ->
--             ( model, Effect.none )
