module Game.Model exposing
    ( Model
    , getGateway
    , init
    , switchActiveGateway
    )

import API.Events.Types as EventTypes
import API.Types
import API.Utils
import Dict exposing (Dict)
import Game.Model.Server as Server exposing (Gateway)
import Game.Model.ServerID as ServerID exposing (RawServerID, ServerID)
import Game.Universe exposing (Universe(..))


type alias Model =
    { universe : Universe
    , mainframeID : ServerID
    , activeGateway : ServerID
    , activeEndpoint : Maybe ServerID
    , gateways : Dict RawServerID Gateway
    , apiCtx : API.Types.InputContext
    }



-- Model


init : API.Types.InputToken -> Universe -> EventTypes.IndexRequested -> Model
init token universe index =
    { universe = universe
    , mainframeID = ServerID.fromValue index.player.mainframe_id
    , activeGateway = ServerID.fromValue index.player.mainframe_id
    , activeEndpoint = Nothing
    , gateways = Server.parseGateways index.player.gateways
    , apiCtx = buildApiContext token universe
    }


getGateway : Model -> ServerID -> Gateway
getGateway model gatewayId =
    Dict.get (ServerID.toValue gatewayId) model.gateways
        |> Maybe.withDefault Server.invalidGateway


switchActiveGateway : ServerID -> Model -> Model
switchActiveGateway newActiveGatewayId model =
    { model | activeGateway = newActiveGatewayId }



-- Utils


buildApiContext : API.Types.InputToken -> Universe -> API.Types.InputContext
buildApiContext token universe =
    let
        apiServer =
            case universe of
                Singleplayer ->
                    API.Types.ServerGameSP

                Multiplayer ->
                    API.Types.ServerGameMP
    in
    API.Utils.buildContext (Just token) apiServer
