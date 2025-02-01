module TestHelpers.Mocks.Events exposing (..)

import API.Events.Types as Events
import Game.Model.ServerID as ServerID


indexRequested : Events.IndexRequested
indexRequested =
    { player =
        { mainframe_id = ServerID.fromValue "gateway_id"
        , gateways = []
        , endpoints = []
        }
    }
