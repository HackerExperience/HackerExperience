module Game.Model.Process exposing
    ( Processes
    , onProcessCompletedEvent
    , onProcessCreatedEvent
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
-- findProcess : ProcessID -> Processes -> Maybe Process
-- findProcess processId processes =
--     OrderedDict.get (ProcessID.toString processId) processes


addProcess : Process -> Processes -> Processes
addProcess process processes =
    OrderedDict.insert (ProcessID.toString process.id) process processes


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
            , parseIndexProcess idxProcess
            )
        )
        idxProcesses
        |> OrderedDict.fromList


parseIndexProcess : Events.IdxProcess -> Process
parseIndexProcess idxProcess =
    let
        data =
            ProcessData.parse idxProcess
    in
    { id = idxProcess.process_id
    , data = data
    , isCompleted = False
    }


parseViewableProcess : { a | process_id : ProcessID, data : String, type_ : String } -> Process
parseViewableProcess viewableProcess =
    let
        data =
            ProcessData.parse viewableProcess
    in
    { id = viewableProcess.process_id
    , data = data
    , isCompleted = False
    }



-- Event Handlers


onProcessCompletedEvent : Events.ProcessCompleted -> Processes -> ( Processes, Action )
onProcessCompletedEvent event processes =
    let
        processData =
            ProcessData.parse event

        maybeOperation =
            case processData of
                ProcessData.LogDelete { logId } ->
                    Just <| ProcessOperation.LogDelete logId

                _ ->
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


onProcessCreatedEvent : Events.ProcessCreated -> Processes -> Processes
onProcessCreatedEvent event processes =
    let
        process =
            parseViewableProcess event
    in
    addProcess process processes
