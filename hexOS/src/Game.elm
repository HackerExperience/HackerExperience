module Game exposing
    ( State
    , Msg(..)
    , init
      -- , update
    )

import Effect exposing (Effect)
import Game.Universe as Universe exposing (Universe)



-- Types


type Msg
    = NoOp


type alias State =
    { sp : Universe.Model
    , mp : Universe.Model
    , currentUniverse : Universe
    }



-- Model


init : Universe -> Universe.Model -> Universe.Model -> ( State, Effect Msg )
init currentUniverse spModel mpModel =
    ( { sp = spModel
      , mp = mpModel
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
