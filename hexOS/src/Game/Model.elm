module Game.Model exposing
    ( Model
    , init
    , switchActiveGateway
    )

import API.Events.Types as EventTypes
import Game.Model.Server as Server exposing (Gateway)
import Game.Model.ServerID as ServerID exposing (ServerID)


type alias Model =
    { mainframeID : ServerID
    , activeGateway : ServerID
    , activeEndpoint : Maybe ServerID
    , gateways : List Gateway
    }



-- Model


init : EventTypes.IndexRequested -> Model
init index =
    { mainframeID = ServerID.fromValue index.player.mainframe_id
    , activeGateway = ServerID.fromValue index.player.mainframe_id
    , activeEndpoint = Nothing
    , gateways = List.map Server.parseGateway index.player.gateways
    }


switchActiveGateway : ServerID -> Model -> Model
switchActiveGateway newActiveGatewayId model =
    { model | activeGateway = newActiveGatewayId }
