module TestHelpers.Models exposing (..)

import API.Types
import Apps.Manifest as App
import Dict
import Game exposing (Model)
import Game.Model.NIP as NIP exposing (NIP)
import Game.Model.Server exposing (Endpoint, Gateway, Server)
import Game.Universe as Universe exposing (Universe(..))
import HUD.ConnectionInfo as CI
import OS
import OS.AppID exposing (AppID)
import OS.Bus as Bus
import State exposing (State)
import TestHelpers.Mocks.Events as Mocks
import WM



-- State


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


withUniverse : Universe -> State -> State
withUniverse universe state_ =
    { state_ | currentUniverse = universe }


withGame : Model -> State -> State
withGame game_ state_ =
    case state_.currentUniverse of
        Singleplayer ->
            withSpGame game_ state_

        Multiplayer ->
            withMpGame game_ state_


withSpGame : Model -> State -> State
withSpGame spGame state_ =
    { state_ | sp = spGame }


withMpGame : Model -> State -> State
withMpGame mpGame state_ =
    { state_ | mp = mpGame }


getGame : State -> Model
getGame state_ =
    case state_.currentUniverse of
        Singleplayer ->
            getSpGame state_

        Multiplayer ->
            getMpGame state_


getSpGame : State -> Model
getSpGame state_ =
    state_.sp


getMpGame : State -> Model
getMpGame state_ =
    state_.mp



-- Game


game : Model
game =
    Game.init (API.Types.InputToken "t0k3n") Singleplayer Mocks.indexRequested


withServer : Server -> Model -> Model
withServer server game_ =
    { game_ | servers = Dict.insert (NIP.toString server.nip) server game_.servers }


withGateway : Gateway -> Model -> Model
withGateway gateway game_ =
    { game_ | gateways = Dict.insert (NIP.toString gateway.nip) gateway game_.gateways }


getServer : NIP -> Model -> Server
getServer nip game_ =
    Game.getServer game_ nip



-- gameWith
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
