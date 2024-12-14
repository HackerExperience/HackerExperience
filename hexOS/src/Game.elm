module Game exposing
    ( Model
    , buildApiContext
    , getActiveGateway
    , getGateway
    , getGateways
    , init
    , onTunnelCreatedEvent
    , switchActiveEndpoint
    , switchActiveGateway
    )

import API.Events.Types as Events
import API.Types
import API.Utils
import Dict exposing (Dict)
import Game.Model.NIP exposing (NIP)
import Game.Model.Server as Server exposing (Gateway)
import Game.Model.ServerID as ServerID exposing (RawServerID, ServerID)
import Game.Universe exposing (Universe(..))


type alias Model =
    { universe : Universe
    , mainframeID : ServerID
    , activeGateway : ServerID
    , activeEndpoint : Maybe NIP
    , gateways : Dict RawServerID Gateway
    , apiCtx : API.Types.InputContext
    }



-- Model


init : API.Types.InputToken -> Universe -> Events.IndexRequested -> Model
init token universe index =
    { universe = universe
    , mainframeID = index.player.mainframe_id
    , activeGateway = index.player.mainframe_id
    , gateways = Server.parseGateways index.player.gateways
    , apiCtx = buildApiContext token universe

    -- `activeEndpoint` will be filled at `initSetActiveEndpoint`
    , activeEndpoint = Nothing
    }
        |> initSetActiveEndpoint


initSetActiveEndpoint : Model -> Model
initSetActiveEndpoint model =
    let
        activeGatewayFirstTunnel =
            List.head (getActiveGateway model).tunnels

        activeEndpoint =
            Maybe.map (\t -> t.targetNip) activeGatewayFirstTunnel
    in
    { model | activeEndpoint = activeEndpoint }


getGateway : Model -> ServerID -> Gateway
getGateway model gatewayId =
    Dict.get (ServerID.toValue gatewayId) model.gateways
        |> Maybe.withDefault Server.invalidGateway


getGateways : Model -> List Gateway
getGateways model =
    Dict.values model.gateways


getActiveGateway : Model -> Gateway
getActiveGateway model =
    getGateway model model.activeGateway


switchActiveGateway : ServerID -> Model -> Model
switchActiveGateway newActiveGatewayId model =
    { model | activeGateway = newActiveGatewayId }


switchActiveEndpoint : NIP -> Model -> Model
switchActiveEndpoint newActiveEndpointNip model =
    { model | activeEndpoint = Just newActiveEndpointNip }


onTunnelCreatedEvent : Model -> Events.TunnelCreated -> Model
onTunnelCreatedEvent model event =
    { model | activeEndpoint = Just event.target_nip }



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
