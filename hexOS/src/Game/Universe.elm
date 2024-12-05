module Game.Universe exposing
    ( Universe(..)
    , isUniverseStringValid
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


isUniverseStringValid : String -> ( Bool, Universe )
isUniverseStringValid rawUniverse =
    case rawUniverse of
        "singleplayer" ->
            ( True, Singleplayer )

        "multiplayer" ->
            ( True, Multiplayer )

        _ ->
            ( False, Singleplayer )
