module Game.Model exposing
    ( Model
    , getGateway
    , init
    , switchActiveGateway
    )

import API.Events.Types as EventTypes
import Dict exposing (Dict)
import Game.Model.Server as Server exposing (Gateway)
import Game.Model.ServerID as ServerID exposing (RawServerID, ServerID)
import Game.Universe exposing (Universe)


type alias Model =
    { universe : Universe
    , mainframeID : ServerID
    , activeGateway : ServerID
    , activeEndpoint : Maybe ServerID
    , gateways : Dict RawServerID Gateway
    }



-- Model


init : Universe -> EventTypes.IndexRequested -> Model
init universe index =
    { universe = universe
    , mainframeID = ServerID.fromValue index.player.mainframe_id
    , activeGateway = ServerID.fromValue index.player.mainframe_id
    , activeEndpoint = Nothing
    , gateways = Server.parseGateways index.player.gateways
    }


getGateway : Model -> ServerID -> Gateway
getGateway model gatewayId =
    Dict.get (ServerID.toValue gatewayId) model.gateways
        |> Maybe.withDefault Server.invalidGateway


switchActiveGateway : ServerID -> Model -> Model
switchActiveGateway newActiveGatewayId model =
    { model | activeGateway = newActiveGatewayId }
