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


type alias Model =
    { mainframeID : Int
    , activeGateway : Int
    , activeEndpoint : Maybe Int
    }



-- Model


init : EventTypes.IndexRequested -> Model
init index =
    { mainframeID = index.player.mainframe_id
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
