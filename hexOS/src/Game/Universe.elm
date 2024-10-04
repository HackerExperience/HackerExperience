module Game.Universe exposing
    ( Model
    , Universe(..)
    , init
    )

-- I'd rather IndexRequested type to be in API.Types (or even Event.Types or whatever)

import API.Events.Types as EventTypes



-- Types


type Universe
    = Singleplayer
    | Multiplayer


type alias Model =
    { universe : Universe
    , mainframeID : Int
    }



-- Model


init : Universe -> EventTypes.IndexRequested -> Model
init universe index =
    { universe = universe
    , mainframeID = index.player.mainframe_id
    }
