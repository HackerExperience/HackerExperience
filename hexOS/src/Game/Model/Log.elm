module Game.Model.Log exposing
    ( Log
    , LogType(..)
    , Logs
    , findLog
    , getLog
    , handleProcessOperation
    , invalidLog
    , logsToList
    , onLogDeletedEvent
    , parse
    , parseLog
    )

import API.Events.Types as Events
import Game.Model.LogData as LogData exposing (LogDataEmpty, LogDataNIP)
import Game.Model.LogID as LogID exposing (LogID, RawLogID)
import Game.Model.NIP as NIP exposing (NIP)
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
    = ServerLoginSelf LogDataEmpty
    | ServerLoginGateway LogDataNIP
    | ServerLoginEndpoint LogDataNIP
    | CustomLog LogDataEmpty


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
    , type_ = CustomLog {}
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
        logType =
            parseLogType log.type_ log.direction log.data
    in
    { id = LogID.fromValue log.id
    , revisionId = log.revision_id
    , type_ = logType
    , rawText = generateText logType
    , isDeleted = log.is_deleted
    , currentOp = Nothing
    }


parseLogType : String -> String -> String -> LogType
parseLogType strLogType strDirection rawData =
    case ( strLogType, strDirection ) of
        ( "server_login", "self" ) ->
            ServerLoginSelf {}

        ( "server_login", "to_ap" ) ->
            ServerLoginGateway <| LogData.parseLogDataNip rawData

        ( "server_login", "from_en" ) ->
            ServerLoginEndpoint <| LogData.parseLogDataNip rawData

        _ ->
            CustomLog {}


generateText : LogType -> String
generateText logType =
    case logType of
        ServerLoginSelf _ ->
            "localhost logged in"

        ServerLoginGateway { nip } ->
            "localhost logged in to [" ++ NIP.getIPString nip ++ "]"

        ServerLoginEndpoint { nip } ->
            "[" ++ NIP.getIPString nip ++ "] logged in to localhost"

        CustomLog _ ->
            "custom"



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
