module Game.Model.Server exposing
    ( Gateway
    , invalidGateway
    , listLogs
    , parseGateways
    )

import API.Events.Types as EventTypes
import Dict exposing (Dict)
import Game.Model.Log as Log exposing (Log, Logs)
import Game.Model.ServerID as ServerID exposing (RawServerID, ServerID)
import OrderedDict



-- Types


type alias Gateway =
    { id : ServerID
    , logs : Logs
    }



-- Model


parseGateways : List EventTypes.IdxGateway -> Dict RawServerID Gateway
parseGateways idxGateways =
    List.map (\idxGateway -> ( idxGateway.id, parseGateway idxGateway )) idxGateways
        |> Dict.fromList


parseGateway : EventTypes.IdxGateway -> Gateway
parseGateway gateway =
    { id = ServerID.fromValue gateway.id

    -- , logs = List.map Log.parse gateway.logs
    , logs = Log.parse gateway.logs
    }


invalidGateway : Gateway
invalidGateway =
    { id = ServerID.fromValue 0
    , logs = OrderedDict.empty
    }



-- Model > Logs


listLogs : Gateway -> List Log
listLogs server =
    Log.logsToList server.logs
