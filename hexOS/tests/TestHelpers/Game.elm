module TestHelpers.Game exposing (..)

import Game.Universe exposing (Universe(..))
import State exposing (State)


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
