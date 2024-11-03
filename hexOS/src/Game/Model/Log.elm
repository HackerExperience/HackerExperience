module Game.Model.Log exposing
    ( Log
    , Logs
    , logsToList
    , parse
    )

import API.Events.Types as EventTypes
import Game.Model.LogID as LogID exposing (LogID, RawLogID)
import OrderedDict exposing (OrderedDict)



-- Types


type alias Logs =
    OrderedDict RawLogID Log


type alias Log =
    { id : LogID
    , revisionId : Int
    , type_ : String
    }



-- Model


parse : List EventTypes.IdxLog -> Logs
parse idxLogs =
    List.map (\idxLog -> ( idxLog.id, parseLog idxLog )) idxLogs
        |> OrderedDict.fromList


parseLog : EventTypes.IdxLog -> Log
parseLog log =
    { id = LogID.fromValue log.id
    , revisionId = log.revision_id

    -- TODO: Here I can convert from STring to LogType, however of course it's better to do that
    -- at the OpenAPI spec level. Investigate if feasible.
    , type_ = log.type_
    }


logsToList : Logs -> List Log
logsToList logs =
    OrderedDict.toList logs
        |> List.map (\( _, log ) -> log)
