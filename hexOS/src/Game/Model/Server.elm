module Game.Model.Server exposing
    ( Endpoint
    , Gateway
    , Server
    , ServerType(..)
    , invalidGateway
    , invalidServer
    , listLogs
    , onTunnelCreatedEvent
    , parseEndpoint
    , parseEndpoints
    , parseGateways
    , parseServers
    , switchActiveEndpoint
    )

import API.Events.Types as Events
import Dict exposing (Dict)
import Game.Model.Log as Log exposing (Log, Logs)
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
    }


type alias Endpoint =
    { nip : NIP
    }


type ServerType
    = ServerGateway
    | ServerEndpoint



-- Model > Server


buildServer : ServerType -> List Events.IdxLog -> NIP -> Maybe TunnelID -> Server
buildServer serverType idxLogs nip tunnelId =
    { nip = nip
    , logs = Log.parse idxLogs
    , type_ = serverType
    , tunnelId = tunnelId
    }


parseServers :
    Dict RawNIP Gateway
    -> List Events.IdxGateway
    -> List Events.IdxEndpoint
    -> Dict RawNIP Server
parseServers gateways idxGateways idxEndpoints =
    let
        gatewaysList =
            Dict.values gateways

        allTunnels =
            List.concatMap (\{ tunnels } -> tunnels) gatewaysList
    in
    Dict.fromList (buildGatewayServers idxGateways ++ buildEndpointServers allTunnels idxEndpoints)


buildGatewayServers : List Events.IdxGateway -> List ( RawNIP, Server )
buildGatewayServers idxGateways =
    let
        buildGatewayServer =
            \gtw ->
                buildServer ServerGateway gtw.logs gtw.nip Nothing
    in
    List.foldl (\gtw acc -> ( NIP.toString gtw.nip, buildGatewayServer gtw ) :: acc)
        []
        idxGateways


buildEndpointServers : Tunnels -> List Events.IdxEndpoint -> List ( RawNIP, Server )
buildEndpointServers allTunnels idxEndpoints =
    let
        findTunnel =
            \nip ->
                Tunnel.findTunnelByTargetNip allTunnels nip
                    |> Maybe.map .id

        buildEndpointServer =
            \endp ->
                buildServer ServerEndpoint endp.logs endp.nip (findTunnel endp.nip)
    in
    List.foldl (\endp acc -> ( NIP.toString endp.nip, buildEndpointServer endp ) :: acc)
        []
        idxEndpoints


invalidServer : Server
invalidServer =
    { nip = NIP.invalidNip
    , logs = OrderedDict.empty
    , type_ = ServerGateway
    , tunnelId = Nothing
    }



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
    }


invalidGateway : Gateway
invalidGateway =
    { nip = NIP.invalidNip
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
    }


switchActiveEndpoint : Gateway -> NIP -> Gateway
switchActiveEndpoint gateway endpointNip =
    case Tunnel.findTunnelByTargetNip gateway.tunnels endpointNip of
        Just _ ->
            { gateway | activeEndpoint = Just endpointNip }

        Nothing ->
            gateway



-- Model > Logs


listLogs : Server -> List Log
listLogs server =
    Log.logsToList server.logs



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
