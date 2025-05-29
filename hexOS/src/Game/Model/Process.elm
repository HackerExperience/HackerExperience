module Game.Model.Process exposing
    ( Processes
    , parse
    )

import API.Events.Types as Events
import Game.Model.ProcessData as ProcessData exposing (ProcessData)
import Game.Model.ProcessID as ProcessID exposing (ProcessID, RawProcessID)
import OrderedDict exposing (OrderedDict)


type alias Processes =
    OrderedDict RawProcessID Process


type alias Process =
    { id : ProcessID
    , data : ProcessData
    }


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
    }
