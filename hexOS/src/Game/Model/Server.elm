module Game.Model.Server exposing
    ( Gateway
    , parseGateway
    )

import API.Events.Types as EventTypes
import Game.Model.Log as Log exposing (Log)
import Game.Model.ServerID as ServerID exposing (ServerID)



-- Types


type alias Gateway =
    { id : ServerID
    , logs : List Log
    }



-- Functions


parseGateway : EventTypes.IdxGateway -> Gateway
parseGateway gateway =
    { id = ServerID.fromValue gateway.id
    , logs = List.map Log.parse gateway.logs
    }
