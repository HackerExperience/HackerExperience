module Game.Universe exposing
    ( Universe(..)
    , toString
    )

-- Types


type Universe
    = Singleplayer
    | Multiplayer



-- Utils


toString : Universe -> String
toString universe =
    case universe of
        Singleplayer ->
            "singleplayer"

        Multiplayer ->
            "multiplayer"
