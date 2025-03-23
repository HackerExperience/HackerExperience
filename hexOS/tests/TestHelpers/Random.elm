module TestHelpers.Random exposing (..)

import API.Types
import Dict
import Game
import Game.Universe as Universe exposing (Universe(..))
import HUD.ConnectionInfo as CI
import Random as R exposing (Generator, map, map4)
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
            \gtwNip ->
                { universe = universe
                , mainframeNip = gtwNip
                , activeGateway = gtwNip
                , apiCtx = Game.buildApiContext (API.Types.InputToken "s3cr3t") universe

                -- TODO
                , gateways = Dict.empty
                , endpoints = Dict.empty
                }
    in
    map genGame randomNip


state : Generator State
state =
    let
        genState =
            \sp mp universe_ gtwNip ->
                { sp = sp
                , mp = mp
                , currentUniverse = universe_
                , currentSession = WM.toLocalSessionId gtwNip
                }
    in
    map4 genState (game Singleplayer) (game Multiplayer) universeId randomNip



-- OS
-- HUD
-- HUD > ConnectionInfo


hudCiSelector : Generator CI.Selector
hudCiSelector =
    R.oneOf2 CI.SelectorGateway CI.SelectorEndpoint
