module DevTools.ReviewBypass exposing (enable)

import Game.Universe as Universe


enable : String
enable =
    Universe.toString Universe.Singleplayer
