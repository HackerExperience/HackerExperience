module TestHelpers.Models exposing (..)

import Apps.Manifest as App
import Game exposing (State)
import Game.Model
import Game.Universe as Universe exposing (Universe(..))
import HUD.ConnectionInfo as CI
import OS
import OS.AppID exposing (AppID)
import OS.Bus as Bus
import TestHelpers.Mocks.Events as Mocks
import WM



-- Game


state : State
state =
    let
        index =
            Mocks.indexRequested

        spModel =
            Game.Model.init index
    in
    Game.init Singleplayer spModel spModel
        |> Tuple.first


stateWithUniverse : Universe -> State -> State
stateWithUniverse universe state_ =
    { state_ | currentUniverse = universe }



-- OS


os : OS.Model
os =
    let
        ( model, _ ) =
            OS.init (WM.toSessionId 1) ( 1024, 1024 )
    in
    model


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
