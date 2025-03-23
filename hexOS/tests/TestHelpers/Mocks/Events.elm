module TestHelpers.Mocks.Events exposing (..)

import API.Events.Types as Events
import Game.Model.NIP as NIP


indexRequested : Events.IndexRequested
indexRequested =
    { player =
        { mainframe_nip = NIP.fromString "0@99.98.97.96"
        , gateways = []
        , endpoints = []
        }
    }
