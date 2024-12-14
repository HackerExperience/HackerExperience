module Game.Model.Log exposing
    ( Log
    , Logs
      -- , logsToList
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
    , type_ : LogType
    , rawText : String
    }


type LogType
    = LocalhostLoggedIn
    | CustomLog
    | UnknownLog



-- Model
-- logsToList : Logs -> List Log
-- logsToList logs =
--     OrderedDict.toList logs
--         |> List.map (\( _, log ) -> log)
-- Model > Parser


parse : List EventTypes.IdxLog -> Logs
parse idxLogs =
    List.map (\idxLog -> ( idxLog.id, parseLog idxLog )) idxLogs
        |> OrderedDict.fromList


parseLog : EventTypes.IdxLog -> Log
parseLog log =
    let
        ( type_, rawText ) =
            parseLogType log.type_
    in
    { id = LogID.fromValue log.id
    , revisionId = log.revision_id
    , type_ = type_
    , rawText = rawText
    }


parseLogType : String -> ( LogType, String )
parseLogType strLogType =
    case strLogType of
        "localhost_logged_in" ->
            ( LocalhostLoggedIn, "localhost logged in" )

        _ ->
            ( UnknownLog, "Unknown log" )
