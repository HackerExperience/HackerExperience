module Game.Model.Server exposing
    ( Gateway
    , invalidGateway
      -- , listLogs
    , parseGateways
    , switchActiveEndpoint
    )

import API.Events.Types as EventTypes
import Dict exposing (Dict)
import Game.Model.Log as Log exposing (Logs)
import Game.Model.NIP as NIP exposing (NIP)
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



-- Model > New


parseGateways : List EventTypes.IdxGateway -> Dict RawServerID Gateway
parseGateways idxGateways =
    List.map (\idxGateway -> ( idxGateway.id, parseGateway idxGateway )) idxGateways
        |> Dict.fromList


parseGateway : EventTypes.IdxGateway -> Gateway
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
    { id = ServerID.fromValue 0
    , nip = NIP.invalidNip
    , logs = OrderedDict.empty
    , tunnels = []
    , activeEndpoint = Nothing
    }



-- Model > Endpoint


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
