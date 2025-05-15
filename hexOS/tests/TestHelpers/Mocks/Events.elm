module TestHelpers.Mocks.Events exposing (..)

import API.Events.Types as Events
import Game.Model.LogID as LogID
import Game.Model.NIP as NIP
import Game.Model.ProcessID as ProcessID



-- Index


indexRequested : Events.IndexRequested
indexRequested =
    { player =
        { mainframe_nip = NIP.fromString "0@99.98.97.96"
        , gateways = []
        , endpoints = []
        }
    }


idxGateway : Events.IdxGateway
idxGateway =
    { logs = []
    , nip = NIP.fromString "0@99.98.97.96"
    , tunnels = []
    }


idxLog : Events.IdxLog
idxLog =
    { id = "abc"
    , is_deleted = False
    , revision_id = "a"
    , type_ = "localhost_logged_in"
    }


logDeleted : Events.LogDeleted
logDeleted =
    { log_id = LogID.fromValue "abc"
    , process_id = ProcessID.fromValue "abc"
    , nip = NIP.fromString "0@99.98.97.96"
    }



-- Withs


withId : String -> { a | id : String } -> { a | id : String }
withId id event =
    { event | id = id }
