module Game.Model exposing
    ( Gateway
    , Model
    , init
    , switchActiveGateway
    )

import API.Events.Types as EventTypes
import Game.Model.Log exposing (Log)
import Game.Model.LogID as LogID exposing (LogID)


type alias Gateway =
    { id : Int
    , logs : List Log
    }


type alias Model =
    { mainframeID : Int
    , activeGateway : Int
    , activeEndpoint : Maybe Int
    , gateways : List Gateway
    }



-- Model


init : EventTypes.IndexRequested -> Model
init index =
    { mainframeID = index.player.mainframe_id
    , activeGateway = index.player.mainframe_id
    , activeEndpoint = Nothing
    , gateways = List.map parseGateway index.player.gateways
    }


    --
parseGateway : EventTypes.IdxGateway -> Gateway
parseGateway gateway =
    { id = gateway.id
    , logs = List.map parseLog gateway.logs
    }


parseLog : EventTypes.IdxLog -> Log
parseLog log =
    { id = LogID.fromValue log.id
    , revisionId = log.revision_id

    -- TODO: Here I can convert from STring to LogType, however of course it's better to do that
    -- at the OpenAPI spec level. Investigate if feasible.
    , type_ = log.type_
    }

    ------

switchActiveGateway : Int -> Model -> Model
switchActiveGateway newActiveGatewayId model =
    { model | activeGateway = newActiveGatewayId }
