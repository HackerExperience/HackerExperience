module Game.Model.Server exposing
    ( Endpoint
    , Gateway
    , invalidGateway
      -- , listLogs
    , onTunnelCreatedEvent
    , parseEndpoint
    , parseEndpoints
    , parseGateways
    , switchActiveEndpoint
    )

import API.Events.Types as Events
import Dict exposing (Dict)
import Game.Model.Log as Log exposing (Logs)
import Game.Model.NIP as NIP exposing (NIP, RawNIP)
import Game.Model.ServerID as ServerID exposing (RawServerID, ServerID)
import Game.Model.Tunnel as Tunnel exposing (Tunnels)
import OrderedDict



-- Types


type alias Gateway =
    { id : ServerID
    , nip : NIP
    , logs : Logs
    , tunnels : Tunnels
    , activeEndpoint : Maybe NIP
    }


type alias Endpoint =
    { nip : NIP
    , logs : Logs
    }



-- Model > Gateway


parseGateways : List Events.IdxGateway -> Dict RawServerID Gateway
parseGateways idxGateways =
    List.map (\idxGateway -> ( idxGateway.id, parseGateway idxGateway )) idxGateways
        |> Dict.fromList


parseGateway : Events.IdxGateway -> Gateway
parseGateway gateway =
    let
        tunnels =
            Tunnel.parse gateway.tunnels

        activeEndpoint =
            Maybe.map (\t -> t.targetNip) (List.head tunnels)
    in
    { id = ServerID.fromValue gateway.id
    , nip = gateway.nip
    , logs = Log.parse gateway.logs
    , tunnels = Tunnel.parse gateway.tunnels
    , activeEndpoint = activeEndpoint
    }


invalidGateway : Gateway
invalidGateway =
    { id = ServerID.fromValue "invalid_server"
    , nip = NIP.invalidNip
    , logs = OrderedDict.empty
    , tunnels = []
    , activeEndpoint = Nothing
    }



-- Model > Endpoint


parseEndpoints : List Events.IdxEndpoint -> Dict RawNIP Endpoint
parseEndpoints idxEndpoints =
    List.map (\idxEndpoint -> ( NIP.toString idxEndpoint.nip, parseEndpoint idxEndpoint )) idxEndpoints
        |> Dict.fromList


parseEndpoint : Events.IdxEndpoint -> Endpoint
parseEndpoint endpoint =
    { nip = endpoint.nip
    , logs = Log.parse endpoint.logs
    }


switchActiveEndpoint : Gateway -> NIP -> Gateway
switchActiveEndpoint gateway endpointNip =
    case Tunnel.findTunnelWithTargetNip gateway.tunnels endpointNip of
        Just _ ->
            { gateway | activeEndpoint = Just endpointNip }

        Nothing ->
            gateway



-- Model > Logs
-- listLogs : Gateway -> List Log
-- listLogs server =
--     Log.logsToList server.logs
-- Event handlers


onTunnelCreatedEvent : Events.TunnelCreated -> Gateway -> Gateway
onTunnelCreatedEvent event gateway =
    let
        tunnel =
            Tunnel.fromTunnelCreatedEvent event
    in
    { gateway
        | tunnels = tunnel :: gateway.tunnels
        , activeEndpoint = Just event.target_nip
    }
