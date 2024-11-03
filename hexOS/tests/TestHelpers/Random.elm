module TestHelpers.Random exposing (..)

import Game exposing (State)
import Game.Model as Game
import Game.Universe as Universe exposing (Universe(..))
import HUD.ConnectionInfo as CI
import Random as R exposing (Generator, int, map, map3, maxInt)
import Random.Extra as R
import Random.List as R
import TestHelpers.Support.RandomUtils as R



-- Game


serverId : Generator Int
serverId =
    int 1 maxInt


universeId : Generator Universe
universeId =
    R.oneOf2 Singleplayer Multiplayer


game : Generator Game.Model
game =
    let
        genGame =
            \gatewayId ->
                { mainframeID = gatewayId
                , activeGateway = gatewayId
                , activeEndpoint = Nothing
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
    map3 genState game game universeId



-- OS
-- HUD
-- HUD > ConnectionInfo


hudCiSelector : Generator CI.Selector
hudCiSelector =
    R.oneOf2 CI.SelectorGateway CI.SelectorEndpoint
