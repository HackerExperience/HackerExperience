module TestHelpers.Random exposing (..)

import API.Types
import Dict
import Game exposing (State)
import Game.Model as Game
import Game.Model.ServerID as ServerID exposing (ServerID)
import Game.Universe as Universe exposing (Universe(..))
import HUD.ConnectionInfo as CI
import Random as R exposing (Generator, int, map, map3, maxInt)
import Random.Extra as R
import Random.List as R
import TestHelpers.Support.RandomUtils as R



-- Game


serverId : Generator ServerID
serverId =
    int 1 maxInt
        |> map (\rawId -> ServerID.fromValue rawId)


universeId : Generator Universe
universeId =
    R.oneOf2 Singleplayer Multiplayer


game : Universe -> Generator Game.Model
game universe =
    let
        genGame =
            \gatewayId ->
                { universe = universe
                , mainframeID = gatewayId
                , activeGateway = gatewayId
                , activeEndpoint = Nothing
                , apiCtx = Game.buildApiContext (API.Types.InputToken "s3cr3t") universe

                -- TODO
                , gateways = Dict.empty
                }
    in
    map genGame serverId


state : Generator State
state =
    let
        genState =
            \sp mp universe_ ->
                { sp = sp
                , mp = mp
                , currentUniverse = universe_
                }
    in
    map3 genState (game Singleplayer) (game Multiplayer) universeId



-- OS
-- HUD
-- HUD > ConnectionInfo


hudCiSelector : Generator CI.Selector
hudCiSelector =
    R.oneOf2 CI.SelectorGateway CI.SelectorEndpoint
