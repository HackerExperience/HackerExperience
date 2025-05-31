module Game.Model.Log exposing
    ( Log
    , LogType(..)
    , Logs
    , findLog
    , getLog
    , handleProcessOperation
    , logsToList
    , onLogDeletedEvent
    , parse
    , parseLog
    )

import API.Events.Types as Events
import Game.Model.LogID as LogID exposing (LogID, RawLogID)
import Game.Model.ProcessID exposing (ProcessID)
import Game.Model.ProcessOperation as Operation exposing (Operation)
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
    , currentOp : Maybe LogOperation
    }


type LogType
    = LocalhostLoggedIn
    | CustomLog


type LogOperation
    = OpStartingLogDelete
    | OpDeletingLog ProcessID



-- Model


logsToList : Logs -> List Log
logsToList logs =
    OrderedDict.toList logs
        |> List.map (\( _, log ) -> log)


getLog : LogID -> Logs -> Log
getLog logId logs =
    findLog logId logs
        |> Maybe.withDefault invalidLog


findLog : LogID -> Logs -> Maybe Log
findLog logId logs =
    OrderedDict.get (LogID.toString logId) logs


updateLog : LogID -> (Log -> Log) -> Logs -> Logs
updateLog logId updater logs =
    let
        justUpdateIt =
            \maybeLog ->
                case maybeLog of
                    Just log ->
                        Just <| updater log

                    Nothing ->
                        Nothing
    in
    OrderedDict.update (LogID.toString logId) justUpdateIt logs


invalidLog : Log
invalidLog =
    { id = LogID.fromValue "invalid"
    , revisionId = "revId"
    , type_ = CustomLog
    , rawText = "Invalid log"
    , isDeleted = False
    , currentOp = Nothing
    }



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
    , currentOp = Nothing
    }


parseLogType : String -> ( LogType, String )
parseLogType strLogType =
    case strLogType of
        "localhost_logged_in" ->
            ( LocalhostLoggedIn, "localhost logged in" )

        _ ->
            -- ( UnknownLog, "Unknown log" )
            ( LocalhostLoggedIn, "localhost logged in" )



-- Process handlers


handleProcessOperation : Operation -> Logs -> Logs
handleProcessOperation operation logs =
    case operation of
        Operation.Starting (Operation.LogDelete logId) ->
            updateLog logId (\log -> { log | currentOp = Just OpStartingLogDelete }) logs

        Operation.Started (Operation.LogDelete logId) processId ->
            updateLog logId (\log -> { log | currentOp = Just <| OpDeletingLog processId }) logs

        Operation.Finished (Operation.LogDelete logId) _ ->
            updateLog logId (\log -> { log | currentOp = Nothing }) logs

        Operation.StartFailed (Operation.LogDelete logId) ->
            updateLog logId (\log -> { log | currentOp = Nothing }) logs



-- Event Handlers


onLogDeletedEvent : Events.LogDeleted -> Logs -> Logs
onLogDeletedEvent event logs =
    updateLog event.log_id (\log -> { log | isDeleted = True }) logs
