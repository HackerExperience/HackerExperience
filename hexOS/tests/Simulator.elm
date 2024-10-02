module Simulator exposing (simulateEffect)

import API.SimulatedLobby as LobbyAPI
import Effect exposing (APIRequestEnum(..), Effect)
import Main
import ProgramTest exposing (SimulatedEffect)
import SimulatedEffect.Cmd
import SimulatedEffect.Task


simulateEffect : Effect Main.Msg -> SimulatedEffect Main.Msg
simulateEffect effect =
    case effect of
        Effect.None ->
            SimulatedEffect.Cmd.none

        Effect.Batch effects ->
            SimulatedEffect.Cmd.batch (List.map simulateEffect effects)

        Effect.MsgToCmd delay msg ->
            -- TODO
            SimulatedEffect.Cmd.none

        Effect.StartSSESubscription token ->
            -- TODO
            SimulatedEffect.Cmd.none

        Effect.DebouncedCmd cmd ->
            -- TODO
            SimulatedEffect.Cmd.none

        Effect.APIRequest apiRequest ->
            case apiRequest of
                LobbyLogin result config ->
                    SimulatedEffect.Task.attempt result (LobbyAPI.loginTask config)