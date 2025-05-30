module Game.Model.Process exposing
    ( Processes
    , onProcessCompletedEvent
    , parse
    )

import API.Events.Types as Events
import Game.Bus as Action exposing (Action)
import Game.Model.ProcessData as ProcessData exposing (ProcessData)
import Game.Model.ProcessID as ProcessID exposing (ProcessID, RawProcessID)
import Game.Model.ProcessOperation as ProcessOperation
import OrderedDict exposing (OrderedDict)


type alias Processes =
    OrderedDict RawProcessID Process


type alias Process =
    { id : ProcessID
    , data : ProcessData
    , isCompleted : Bool
    }



-- Model
-- getProcess : ProcessID -> Processes -> Process
-- getProcess processId processes =
--     findProcess processId processes
--         |> Maybe.withDefault invalidProcess


findProcess : ProcessID -> Processes -> Maybe Process
findProcess processId processes =
    OrderedDict.get (ProcessID.toString processId) processes


updateProcess : ProcessID -> (Process -> Process) -> Processes -> Processes
updateProcess processId updater processes =
    let
        justUpdateIt =
            \maybeProcess ->
                case maybeProcess of
                    Just process ->
                        Just <| updater process

                    Nothing ->
                        Nothing
    in
    OrderedDict.update (ProcessID.toString processId) justUpdateIt processes



-- invalidProcess : Process
-- invalidProcess =
--     { id = ProcessID.fromValue "invalid"
--     , data = ProcessData.InvalidProcess "invalid"
--     , isCompleted = False
--     }
-- Model > Parser


parse : List Events.IdxProcess -> Processes
parse idxProcesses =
    List.map
        (\idxProcess ->
            ( ProcessID.toValue idxProcess.process_id
            , parseProcess idxProcess
            )
        )
        idxProcesses
        |> OrderedDict.fromList


parseProcess : Events.IdxProcess -> Process
parseProcess idxProcess =
    let
        data =
            ProcessData.parse idxProcess
    in
    { id = idxProcess.process_id
    , data = data
    , isCompleted = False
    }



-- Event Handlers


onProcessCompletedEvent : Events.ProcessCompleted -> Processes -> ( Processes, Action )
onProcessCompletedEvent event processes =
    let
        maybeProcessData =
            findProcess event.process_id processes
                |> Maybe.map .data

        maybeOperation =
            case maybeProcessData of
                Just (ProcessData.LogDelete { logId }) ->
                    Just <| ProcessOperation.LogDelete logId

                Just _ ->
                    Nothing

                Nothing ->
                    Nothing

        action =
            case maybeOperation of
                Just operationType ->
                    Action.ProcessOperation
                        event.nip
                        (ProcessOperation.Finished operationType event.process_id)

                Nothing ->
                    Action.ActionNoOp
    in
    ( updateProcess event.process_id (\process -> { process | isCompleted = True }) processes
    , action
    )
