module Game exposing
    ( Msg(..)
    , State
    , getActiveGateway
    , getActiveUniverse
    , init
    )

import Effect exposing (Effect)
import Game.Universe as Universe exposing (Universe(..))



-- Types


type Msg
    = NoOp


type alias State =
    { sp : Universe.Model
    , mp : Universe.Model

    -- TODO: rename to `activeUniverse`
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


getActiveUniverse : State -> Universe.Model
getActiveUniverse state =
    case state.currentUniverse of
        Singleplayer ->
            state.sp

        Multiplayer ->
            state.mp


getActiveGateway : State -> Int
getActiveGateway state =
    (getActiveUniverse state).activeGateway



-- Update
-- update : Msg -> Model -> ( Model, Effect Msg )
-- update msg model =
--     case msg of
--         NoOp ->
--             ( model, Effect.none )
