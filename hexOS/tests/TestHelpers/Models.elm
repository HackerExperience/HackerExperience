module TestHelpers.Models exposing (..)

import API.Types
import Apps.Manifest as App
import Game
import Game.Universe as Universe exposing (Universe(..))
import HUD.ConnectionInfo as CI
import OS
import OS.AppID exposing (AppID)
import OS.Bus as Bus
import State exposing (State)
import TestHelpers.Mocks.Events as Mocks
import WM



-- Game


state : State
state =
    let
        index =
            Mocks.indexRequested

        gtwNip =
            index.player.mainframe_nip

        spModel =
            Game.init (API.Types.InputToken "t0k3n") Singleplayer index
    in
    State.init Singleplayer (WM.toLocalSessionId gtwNip) spModel spModel
        |> Tuple.first


stateWithUniverse : Universe -> State -> State
stateWithUniverse universe state_ =
    { state_ | currentUniverse = universe }



-- OS


os : OS.Model
os =
    OS.init ( 1024, 1024 )
        |> Tuple.first


osWithApp : OS.Model -> ( OS.Model, AppID )
osWithApp model =
    model
        |> OS.update state (OS.PerformAction (Bus.OpenApp App.DemoApp Nothing))
        |> Tuple.mapSecond (\_ -> model.wm.nextAppId)



-- HUD
-- HUD > ConnectionInfo


hudCi : CI.Model
hudCi =
    CI.initialModel


hudCiWithSelector : CI.Selector -> CI.Model
hudCiWithSelector selector =
    { hudCi | selector = selector }
