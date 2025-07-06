module TestHelpers.Random exposing (..)

import API.Types
import Dict
import Game
import Game.Model.ServerID as ServerID
import Game.Universe as Universe exposing (Universe(..))
import HUD.ConnectionInfo as CI
import Random as R exposing (Generator, map2, map5)
import Random.Extra as R
import Random.List as R
import State exposing (State)
import TestHelpers.Random.Utils exposing (randomId, randomNip)
import TestHelpers.Support.RandomUtils as R
import WM



-- Game


universeId : Generator Universe
universeId =
    R.oneOf2 Singleplayer Multiplayer


game : Universe -> Generator Game.Model
game universe =
    let
        genGame =
            \rawGtwId gtwNip ->
                { universe = universe
                , mainframeId = ServerID.fromValue rawGtwId
                , mainframeNip = gtwNip
                , activeGateway = gtwNip
                , apiCtx = Game.buildApiContext (API.Types.InputToken "s3cr3t") universe

                -- TODO
                , gateways = Dict.empty
                , endpoints = Dict.empty
                , servers = Dict.empty
                , manifest = Dict.empty
                }
    in
    map2 genGame randomId randomNip


state : Generator State
state =
    let
        genState =
            \sp mp universe_ rawGtwId gtwNip ->
                { sp = sp
                , mp = mp
                , currentUniverse = universe_
                , currentSession = WM.toLocalSessionId (ServerID.fromValue rawGtwId) gtwNip
                }
    in
    map5 genState (game Singleplayer) (game Multiplayer) universeId randomId randomNip



-- OS
-- HUD
-- HUD > ConnectionInfo


hudCiSelector : Generator CI.Selector
hudCiSelector =
    R.oneOf2 CI.SelectorGateway CI.SelectorEndpoint
