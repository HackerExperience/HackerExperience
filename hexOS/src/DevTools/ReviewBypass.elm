module DevTools.ReviewBypass exposing
    ( gameGetInactiveUniverse
    , modelToValueInt
    , universeToString
    )

import Game exposing (State)
import Game.Model.LogID as LogID
import Game.Universe as Universe


universeToString : String
universeToString =
    Universe.toString Universe.Singleplayer


gameGetInactiveUniverse : State -> Universe.Model
gameGetInactiveUniverse =
    Game.getInactiveUniverse


modelToValueInt : List Int
modelToValueInt =
    [ LogID.toValue ]
