module Game.Model exposing
    ( Model
    , init
    , switchActiveGateway
    )

import API.Events.Types as EventTypes


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
