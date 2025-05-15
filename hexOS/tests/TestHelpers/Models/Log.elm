module TestHelpers.Models.Log exposing (..)

import API.Events.Types as Events
import Game.Model.Log as Log exposing (Log)
import TestHelpers.Mocks.Events as Mocks


new : Log
new =
    fromIndex Mocks.idxLog


fromIndex : Events.IdxLog -> Log
fromIndex idxLog =
    Log.parseLog idxLog
