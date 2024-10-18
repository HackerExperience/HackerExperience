module DevTools.ReviewBypass exposing (gameGetInactiveUniverse, universeToString)

import Game exposing (State)
import Game.Universe as Universe


universeToString : String
universeToString =
    Universe.toString Universe.Singleplayer


gameGetInactiveUniverse : State -> Universe.Model
gameGetInactiveUniverse =
    Game.getInactiveUniverse
