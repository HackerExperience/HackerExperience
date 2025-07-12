module TestHelpers.Mocks.Events exposing (..)

import API.Events.Types as Events
import Game.Model.LogID as LogID exposing (LogID)
import Game.Model.NIP as NIP exposing (NIP)
import Game.Model.ProcessID as ProcessID
import Game.Model.ServerID as ServerID



-- Index


indexRequested : Events.IndexRequested
indexRequested =
    { player =
        { mainframe_id = "srvid"
        , mainframe_nip = defaultNip
        , gateways = []
        , endpoints = []
        }
    , software =
        { manifest = []
        }
    }


idxGateway : Events.IdxGateway
idxGateway =
    { id = "srvid"
    , nip = defaultNip
    , installations = []
    , tunnels = []
    , files = []
    , logs = []
    , processes = []
    }


idxLog : Events.IdxLog
idxLog =
    { id = "abc"
    , is_deleted = False
    , revision_count = 1
    , revisions = [ idxLogRevision ]
    , sort_strategy = "newest_first"
    }


idxLogRevision : Events.IdxLogRevision
idxLogRevision =
    { revision_id = 1
    , type_ = "server_login"
    , direction = "self"
    , data = "{}"
    , source = "self"
    }


logDeleted : Events.LogDeleted
logDeleted =
    { log_id = LogID.fromValue "abc"
    , process_id = ProcessID.fromValue "abc"
    , nip = defaultNip
    }


defaultNip : NIP
defaultNip =
    NIP.fromString "0@99.98.97.96"



-- Withs


withId : String -> { a | id : String } -> { a | id : String }
withId id event =
    { event | id = id }


withLog_id : LogID -> { a | log_id : LogID } -> { a | log_id : LogID }
withLog_id id event =
    { event | log_id = id }
