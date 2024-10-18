module TestHelpers.Game exposing (..)

import Game exposing (State)
import Game.Universe exposing (Universe(..))


type alias UniverseInfo =
    { currentUniverse : Universe
    , otherUniverse : Universe
    }


universeInfo : State -> UniverseInfo
universeInfo state =
    { currentUniverse = state.currentUniverse
    , otherUniverse = otherUniverse state.currentUniverse
    }


otherUniverse : Universe -> Universe
otherUniverse universe =
    case universe of
        Singleplayer ->
            Multiplayer

        Multiplayer ->
            Singleplayer
