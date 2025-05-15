module Game.Model.Log exposing
    ( Log
    , LogType(..)
    , Logs
    , logsToList
    , onLogDeletedEvent
    , parse
    , parseLog
    )

import API.Events.Types as Events
import Game.Model.LogID as LogID exposing (LogID, RawLogID)
import OrderedDict exposing (OrderedDict)



-- Types


type alias Logs =
    OrderedDict RawLogID Log


type alias Log =
    { id : LogID
    , revisionId : String
    , type_ : LogType
    , rawText : String
    , isDeleted : Bool
    }


type LogType
    = LocalhostLoggedIn
    | CustomLog



-- Model


logsToList : Logs -> List Log
logsToList logs =
    OrderedDict.toList logs
        |> List.map (\( _, log ) -> log)



-- Model > Parser


parse : List Events.IdxLog -> Logs
parse idxLogs =
    List.map (\idxLog -> ( idxLog.id, parseLog idxLog )) idxLogs
        |> OrderedDict.fromList


parseLog : Events.IdxLog -> Log
parseLog log =
    let
        ( type_, rawText ) =
            parseLogType log.type_
    in
    { id = LogID.fromValue log.id
    , revisionId = log.revision_id
    , type_ = type_
    , rawText = rawText
    , isDeleted = log.is_deleted
    }


parseLogType : String -> ( LogType, String )
parseLogType strLogType =
    case strLogType of
        "localhost_logged_in" ->
            ( LocalhostLoggedIn, "localhost logged in" )

        _ ->
            -- ( UnknownLog, "Unknown log" )
            ( LocalhostLoggedIn, "localhost logged in" )



-- Event Handlers


onLogDeletedEvent : Events.LogDeleted -> Logs -> Logs
onLogDeletedEvent event logs =
    OrderedDict.update
        (LogID.toString event.log_id)
        (Maybe.map (\log -> { log | isDeleted = True }))
        logs
