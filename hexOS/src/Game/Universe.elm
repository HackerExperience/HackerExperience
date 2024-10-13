module Game.Universe exposing
    ( Model
    , Universe(..)
    , init
    , switchActiveGateway
    , toString
    )

-- I'd rather IndexRequested type to be in API.Types (or even Event.Types or whatever)

import API.Events.Types as EventTypes



-- Types


type Universe
    = Singleplayer
    | Multiplayer


{-| todo
-}
type alias ServerID =
    Int


type alias Model =
    { universe : Universe
    , mainframeID : ServerID
    , activeGateway : ServerID
    , activeEndpoint : Maybe ServerID
    }



-- Model


init : Universe -> EventTypes.IndexRequested -> Model
init universe index =
    { universe = universe
    , mainframeID = index.player.mainframe_id
    , activeGateway = index.player.mainframe_id
    , activeEndpoint = Nothing
    }


switchActiveGateway : Int -> Model -> Model
switchActiveGateway newActiveGatewayId model =
    { model | activeGateway = newActiveGatewayId }



-- Utils


toString : Universe -> String
toString universe =
    case universe of
        Singleplayer ->
            "singleplayer"

        Multiplayer ->
            "multiplayer"
