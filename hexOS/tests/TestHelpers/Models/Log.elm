module TestHelpers.Models.Log exposing (..)

import API.Events.Types as Events
import Game.Model.Log as Log exposing (Log, Logs)
import Game.Model.LogID as LogID exposing (LogID)
import OrderedDict
import TestHelpers.Mocks.Events as Mocks


new : Log
new =
    fromIndex Mocks.idxLog


fromIndex : Events.IdxLog -> Log
fromIndex idxLog =
    Log.parseLog idxLog


toLogs : List Log -> Logs
toLogs logsList =
    List.map (\log -> ( LogID.toString log.id, log )) logsList
        |> OrderedDict.fromList


findLog : LogID -> Logs -> Maybe Log
findLog logId logs =
    Log.findLog logId logs


getLog : LogID -> Logs -> Log
getLog logId logs =
    Log.getLog logId logs
