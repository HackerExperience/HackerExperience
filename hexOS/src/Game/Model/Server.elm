module Game.Model.Server exposing
    ( Endpoint
    , Gateway
    , Server
    , invalidGateway
    , invalidServer
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
import Game.Model.Tunnel as Tunnel exposing (Tunnels)
import Game.Model.TunnelID exposing (TunnelID)
import OrderedDict



-- Types


type alias Server =
    { nip : NIP
    , logs : Logs
    , type_ : ServerType
    , tunnelId : Maybe TunnelID
    }


type alias Gateway =
    { nip : NIP
    , tunnels : Tunnels
    , activeEndpoint : Maybe NIP
    , server : Server
    }


type alias Endpoint =
    { nip : NIP
    , server : Server
    }


type ServerType
    = ServerGateway
    | ServerEndpoint



-- Model > Gateway


parseGateways : List Events.IdxGateway -> Dict RawNIP Gateway
parseGateways idxGateways =
    List.map (\idxGateway -> ( NIP.toString idxGateway.nip, parseGateway idxGateway )) idxGateways
        |> Dict.fromList


parseGateway : Events.IdxGateway -> Gateway
parseGateway gateway =
    let
        tunnels =
            Tunnel.parse gateway.tunnels

        activeEndpoint =
            Maybe.map (\t -> t.targetNip) (List.head tunnels)
    in
    { nip = gateway.nip
    , tunnels = Tunnel.parse gateway.tunnels
    , activeEndpoint = activeEndpoint
    , server = buildServer gateway.logs gateway.nip ServerGateway Nothing
    }


invalidGateway : Gateway
invalidGateway =
    { nip = NIP.invalidNip
    , tunnels = []
    , activeEndpoint = Nothing
    , server = invalidServer
    }



-- Model > Endpoint


parseEndpoints : List Events.IdxEndpoint -> Dict RawNIP Endpoint
parseEndpoints idxEndpoints =
    List.map (\idxEndpoint -> ( NIP.toString idxEndpoint.nip, parseEndpoint idxEndpoint )) idxEndpoints
        |> Dict.fromList


parseEndpoint : Events.IdxEndpoint -> Endpoint
parseEndpoint endpoint =
    let
        -- TODO: Extract tunnel from previous parsers
        tunnelId =
            Nothing
    in
    { nip = endpoint.nip
    , server = buildServer endpoint.logs endpoint.nip ServerEndpoint tunnelId
    }


switchActiveEndpoint : Gateway -> NIP -> Gateway
switchActiveEndpoint gateway endpointNip =
    case Tunnel.findTunnelWithTargetNip gateway.tunnels endpointNip of
        Just _ ->
            { gateway | activeEndpoint = Just endpointNip }

        Nothing ->
            gateway



-- Model > Server


buildServer : List Events.IdxLog -> NIP -> ServerType -> Maybe TunnelID -> Server
buildServer idxLogs nip serverType tunnelId =
    { nip = nip
    , logs = Log.parse idxLogs
    , type_ = serverType
    , tunnelId = tunnelId
    }


invalidServer : Server
invalidServer =
    { nip = NIP.invalidNip
    , logs = OrderedDict.empty
    }



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
