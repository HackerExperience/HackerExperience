module Game exposing
    ( Model
    , Msg(..)
    , init
      -- , update
    )

import Effect exposing (Effect)
import Game.Universe as Universe exposing (Universe)
import OS



-- Types


type Msg
    = NoOp


type alias Model =
    { sp : Universe.Model
    , mp : Universe.Model
    , os : OS.Model
    , currentUniverse : Universe
    }



-- Model


init : Universe -> Universe.Model -> Universe.Model -> OS.Model -> ( Model, Effect Msg )
init currentUniverse spModel mpModel osModel =
    ( { sp = spModel
      , mp = mpModel
      , os = osModel
      , currentUniverse = currentUniverse
      }
    , Effect.none
    )



-- Update
-- update : Msg -> Model -> ( Model, Effect Msg )
-- update msg model =
--     case msg of
--         NoOp ->
--             ( model, Effect.none )
