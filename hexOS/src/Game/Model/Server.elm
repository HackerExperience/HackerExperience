module Game.Model.Server exposing
    ( Endpoint
    , Gateway
    , Server
    , ServerType(..)
    , buildServer
    , handleProcessOperation
    , invalidGateway
    , invalidServer
    , listLogs
    , onLogDeletedEvent
    , onLogEditedEvent
    , onProcessCompletedEvent
    , onProcessCreatedEvent
    , onTunnelCreatedEvent
    , parseEndpoint
    , parseEndpoints
    , parseGateways
    , parseServers
    , switchActiveEndpoint
    )

import API.Events.Types as Events
import Dict exposing (Dict)
import Game.Bus exposing (Action)
import Game.Model.Log as Log exposing (Log, Logs)
import Game.Model.NIP as NIP exposing (NIP, RawNIP)
import Game.Model.Process as Process exposing (Process, Processes)
import Game.Model.ProcessData as ProcessData
import Game.Model.ProcessOperation as Operation exposing (Operation)
import Game.Model.Tunnel as Tunnel exposing (Tunnels)
import Game.Model.TunnelID exposing (TunnelID)
import OrderedDict



-- Types


type alias Server =
    { type_ : ServerType
    , nip : NIP
    , logs : Logs
    , tunnelId : Maybe TunnelID
    , processes : Processes
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


buildServer : ServerType -> NIP -> Maybe TunnelID -> List Events.IdxLog -> List Events.IdxProcess -> Server
buildServer serverType nip tunnelId idxLogs idxProcesses =
    { type_ = serverType
    , nip = nip
    , tunnelId = tunnelId
    , logs = Log.parse idxLogs
    , processes = Process.parse idxProcesses
    }
        |> applyProcessOperations


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
                buildServer ServerGateway gtw.nip Nothing gtw.logs gtw.processes
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
                buildServer ServerEndpoint endp.nip (findTunnel endp.nip) endp.logs endp.processes
    in
    List.foldl (\endp acc -> ( NIP.toString endp.nip, buildEndpointServer endp ) :: acc)
        []
        idxEndpoints


{-| For each ongoing/active process, make sure the underlying object is aware that it is being
processed. This ensures the post-login UI ("cold") matches the reactive in-game UI ("hot").
-}
applyProcessOperations : Server -> Server
applyProcessOperations server =
    List.foldl applyProcessOperation server (Process.toList server.processes)


applyProcessOperation : Process -> Server -> Server
applyProcessOperation process server =
    let
        maybeOperationType =
            case process.data of
                ProcessData.LogDelete { logId } ->
                    Just <| Operation.LogDelete logId

                ProcessData.LogEdit { logId } ->
                    Just <| Operation.LogEdit logId

                _ ->
                    Nothing
    in
    case maybeOperationType of
        Just operationType ->
            handleProcessOperation (Operation.Started operationType process.id) server

        Nothing ->
            server


invalidServer : Server
invalidServer =
    { type_ = ServerGateway
    , nip = NIP.invalidNip
    , tunnelId = Nothing
    , logs = OrderedDict.empty
    , processes = OrderedDict.empty
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



-- Process handlers


handleProcessOperation : Operation -> Server -> Server
handleProcessOperation operation server =
    case operation of
        Operation.Starting (Operation.LogDelete _) ->
            handleProcessOperationLog operation server

        Operation.Starting (Operation.LogEdit _) ->
            handleProcessOperationLog operation server

        Operation.Started (Operation.LogDelete _) _ ->
            handleProcessOperationLog operation server

        Operation.Started (Operation.LogEdit _) _ ->
            handleProcessOperationLog operation server

        Operation.Finished (Operation.LogDelete _) _ ->
            handleProcessOperationLog operation server

        Operation.Finished (Operation.LogEdit _) _ ->
            handleProcessOperationLog operation server

        Operation.StartFailed (Operation.LogDelete _) ->
            handleProcessOperationLog operation server

        Operation.StartFailed (Operation.LogEdit _) ->
            handleProcessOperationLog operation server


handleProcessOperationLog : Operation -> Server -> Server
handleProcessOperationLog operation server =
    { server | logs = Log.handleProcessOperation operation server.logs }



-- Event handlers


onLogDeletedEvent : Events.LogDeleted -> Server -> Server
onLogDeletedEvent event server =
    { server | logs = Log.onLogDeletedEvent event server.logs }


onLogEditedEvent : Events.LogEdited -> Server -> Server
onLogEditedEvent event server =
    { server | logs = Log.onLogEditedEvent event server.logs }


onProcessCompletedEvent : Events.ProcessCompleted -> Server -> ( Server, Action )
onProcessCompletedEvent event server =
    let
        ( processes, action ) =
            Process.onProcessCompletedEvent event server.processes
    in
    ( { server | processes = processes }, action )


onProcessCreatedEvent : Events.ProcessCreated -> Server -> ( Server, Action )
onProcessCreatedEvent event server =
    let
        ( processes, action ) =
            Process.onProcessCreatedEvent event server.processes
    in
    ( { server | processes = processes }, action )


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
