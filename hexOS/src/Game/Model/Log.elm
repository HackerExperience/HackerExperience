module Game.Model.Log exposing
    ( Log
    , LogType(..)
    , Logs
    , findLog
    , getLog
    , getMaxRevisionId
    , getNewestRevision
    , getSelectedRevision
    , handleProcessOperation
    , invalidLog
    , logsToList
    , onLogDeletedEvent
    , onLogEditedEvent
    , parse
    , parseLog
    )

import API.Events.Types as Events
import Dict exposing (Dict)
import Game.Model.LogData as LogData exposing (LogDataEmpty, LogDataNIP, LogDataText)
import Game.Model.LogID as LogID exposing (LogID, RawLogID)
import Game.Model.NIP as NIP
import Game.Model.ProcessID exposing (ProcessID)
import Game.Model.ProcessOperation as Operation exposing (Operation)
import OrderedDict exposing (OrderedDict)



-- Types


type alias Logs =
    OrderedDict RawLogID Log


type alias Log =
    { id : LogID
    , revisions : Dict Int LogRevision
    , revisionCount : Int
    , selectedRevisionId : Int
    , isDeleted : Bool
    , sortStrategy : SortRevisionStrategy
    , currentOp : Maybe LogOperation
    }


type alias LogRevision =
    { revisionId : Int
    , type_ : LogType
    , rawText : String
    }


type SortRevisionStrategy
    = NewestRevisionFirst
    | OldestRevisionFirst


type LogType
    = ServerLoginSelf LogDataEmpty
    | ServerLoginGateway LogDataNIP
    | ServerLoginEndpoint LogDataNIP
    | CustomLog LogDataText


type LogOperation
    = OpStartingLogDelete
    | OpStartingLogEdit
    | OpDeletingLog ProcessID
    | OpEditingLog ProcessID



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
    , revisions = Dict.empty
    , revisionCount = 0
    , selectedRevisionId = 0
    , isDeleted = False
    , sortStrategy = NewestRevisionFirst
    , currentOp = Nothing
    }



-- Model > Revisions


getRevision : Int -> Log -> LogRevision
getRevision revId log =
    Maybe.withDefault invalidRevision <| Dict.get revId log.revisions


getSelectedRevision : Log -> Maybe Int -> LogRevision
getSelectedRevision log maybeSelectionOverride =
    case maybeSelectionOverride of
        Just customId ->
            getRevision customId log

        Nothing ->
            getRevision log.selectedRevisionId log


{-| NOTE: Currently, this is only used at LogEditPopup and not too important UX-wise. So if the
implementation gets too tricky (which I think it will in the future), feel free to get rid of it
and simply use `getSelectedRevision` instead.
-}
getNewestRevision : Log -> LogRevision
getNewestRevision log =
    getRevision (getMaxRevisionId log.revisions) log


invalidRevision : LogRevision
invalidRevision =
    { revisionId = 1
    , type_ = CustomLog { text = "Invalid revision" }
    , rawText = "Invalid revision"
    }



-- Model > Parser


parse : List Events.IdxLog -> Logs
parse idxLogs =
    List.map (\idxLog -> ( idxLog.id, parseLog idxLog )) idxLogs
        |> OrderedDict.fromList


parseLog : Events.IdxLog -> Log
parseLog log =
    let
        revisions =
            parseLogRevisions log.revisions

        sortStrategy =
            parseSortStrategy log.sort_strategy

        selectedRevisionId =
            case sortStrategy of
                NewestRevisionFirst ->
                    getMaxRevisionId revisions

                OldestRevisionFirst ->
                    getMinRevisionId revisions
    in
    { id = LogID.fromValue log.id
    , revisions = revisions
    , revisionCount = Dict.size revisions
    , sortStrategy = sortStrategy
    , selectedRevisionId = selectedRevisionId
    , isDeleted = log.is_deleted
    , currentOp = Nothing
    }


parseLogRevisions : List Events.IdxLogRevision -> Dict Int LogRevision
parseLogRevisions revisions =
    List.foldl parseLogRevision Dict.empty revisions


parseLogRevision : Events.IdxLogRevision -> Dict Int LogRevision -> Dict Int LogRevision
parseLogRevision idxRevision acc =
    let
        revType =
            parseLogType idxRevision.type_ idxRevision.direction idxRevision.data

        revision =
            { revisionId = idxRevision.revision_id
            , type_ = revType
            , rawText = generateText revType
            }
    in
    Dict.insert revision.revisionId revision acc


parseLogType : String -> String -> String -> LogType
parseLogType strLogType strDirection rawData =
    case ( strLogType, strDirection ) of
        ( "server_login", "self" ) ->
            ServerLoginSelf {}

        ( "server_login", "to_ap" ) ->
            ServerLoginGateway <| LogData.parseLogDataNip rawData

        ( "server_login", "from_en" ) ->
            ServerLoginEndpoint <| LogData.parseLogDataNip rawData

        ( "custom", "self" ) ->
            CustomLog <| LogData.parseLogDataText rawData

        _ ->
            CustomLog { text = "Unknown log: " ++ strLogType ++ ":" ++ strDirection }


parseSortStrategy : String -> SortRevisionStrategy
parseSortStrategy rawSortStrategy =
    case rawSortStrategy of
        "recover" ->
            OldestRevisionFirst

        _ ->
            NewestRevisionFirst


getMinRevisionId : Dict Int LogRevision -> Int
getMinRevisionId revisions =
    Maybe.withDefault 1 <| List.minimum (Dict.keys revisions)


getMaxRevisionId : Dict Int LogRevision -> Int
getMaxRevisionId revisions =
    Maybe.withDefault 1 <| List.maximum (Dict.keys revisions)


generateText : LogType -> String
generateText logType =
    case logType of
        ServerLoginSelf _ ->
            "localhost logged in"

        ServerLoginGateway { nip } ->
            "localhost logged in to [" ++ NIP.getIPString nip ++ "]"

        ServerLoginEndpoint { nip } ->
            "[" ++ NIP.getIPString nip ++ "] logged in to localhost"

        CustomLog { text } ->
            text



-- Process handlers


handleProcessOperation : Operation -> Logs -> Logs
handleProcessOperation operation logs =
    case operation of
        Operation.Starting (Operation.LogDelete logId) ->
            updateLog logId (\log -> { log | currentOp = Just OpStartingLogDelete }) logs

        Operation.Starting (Operation.LogEdit logId) ->
            updateLog logId (\log -> { log | currentOp = Just OpStartingLogEdit }) logs

        Operation.Started (Operation.LogDelete logId) processId ->
            updateLog logId (\log -> { log | currentOp = Just <| OpDeletingLog processId }) logs

        Operation.Started (Operation.LogEdit logId) processId ->
            updateLog logId (\log -> { log | currentOp = Just <| OpEditingLog processId }) logs

        Operation.Finished (Operation.LogDelete logId) _ ->
            updateLog logId (\log -> { log | currentOp = Nothing }) logs

        Operation.Finished (Operation.LogEdit logId) _ ->
            updateLog logId (\log -> { log | currentOp = Nothing }) logs

        Operation.StartFailed (Operation.LogDelete logId) ->
            updateLog logId (\log -> { log | currentOp = Nothing }) logs

        Operation.StartFailed (Operation.LogEdit logId) ->
            updateLog logId (\log -> { log | currentOp = Nothing }) logs



-- Event Handlers


onLogDeletedEvent : Events.LogDeleted -> Logs -> Logs
onLogDeletedEvent event logs =
    updateLog event.log_id (\log -> { log | isDeleted = True }) logs


onLogEditedEvent : Events.LogEdited -> Logs -> Logs
onLogEditedEvent event logs =
    let
        updateFn =
            \log ->
                let
                    revisionId =
                        log.revisionCount + 1

                    revType =
                        parseLogType event.type_ event.direction event.data

                    revision =
                        { revisionId = revisionId
                        , type_ = revType
                        , rawText = generateText revType
                        }
                in
                { log
                    | revisions = Dict.insert revisionId revision log.revisions
                    , revisionCount = revisionId
                    , selectedRevisionId = revisionId
                    , sortStrategy = NewestRevisionFirst
                }
    in
    updateLog event.log_id updateFn logs
