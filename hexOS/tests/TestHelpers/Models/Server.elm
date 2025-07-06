module TestHelpers.Models.Server exposing (..)

import API.Events.Types as Events
import Game.Model.Log exposing (Log, Logs)
import Game.Model.Server as Server exposing (Endpoint, Gateway, Server, ServerType(..))
import Game.Model.ServerID as ServerID
import TestHelpers.Mocks.Events as Mocks
import TestHelpers.Models.Log as TMLog



-- Server


new : Server
new =
    fromIdxGateway Mocks.idxGateway


fromIdxGateway : Events.IdxGateway -> Server
fromIdxGateway idxGtw =
    Server.buildServer ServerGateway idxGtw.nip Nothing idxGtw.logs idxGtw.files idxGtw.processes



-- Gateway


gatewayFromServer : Server -> Gateway
gatewayFromServer server =
    -- Using a hard-coded ID for now. Not sure yet how tests will use this function
    { id = ServerID.fromValue "todo"
    , nip = server.nip
    , tunnels = []
    , activeEndpoint = Nothing
    }



-- Withs


withLogs : List Log -> Server -> Server
withLogs logs server =
    { server | logs = TMLog.toLogs logs }
