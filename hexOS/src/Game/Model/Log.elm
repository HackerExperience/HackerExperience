module Game.Model.Log exposing
    ( Log
    , parse
    )

import API.Events.Types as EventTypes
import Game.Model.LogID as LogID exposing (LogID)



-- Types


type alias Log =
    { id : LogID
    , revisionId : Int
    , type_ : String
    }



-- Functions


parse : EventTypes.IdxLog -> Log
parse log =
    { id = LogID.fromValue log.id
    , revisionId = log.revision_id

    -- TODO: Here I can convert from STring to LogType, however of course it's better to do that
    -- at the OpenAPI spec level. Investigate if feasible.
    , type_ = log.type_
    }
