module StateTest exposing (suite)

import Event exposing (Event)
import Game.Bus exposing (Action(..))
import Game.Model.LogID as LogID
import Game.Model.NIP as NIP
import Game.Model.ServerID as ServerID
import Game.Msg exposing (Msg(..))
import Game.Universe as Universe exposing (Universe(..))
import State
import TestHelpers.Expect as E
import TestHelpers.Game as TG
import TestHelpers.Mocks.Events as Mocks
import TestHelpers.Models as TM
import TestHelpers.Models.Log as TMLog
import TestHelpers.Models.Server as TMServer
import TestHelpers.Random as TR
import TestHelpers.Test exposing (Test, describe, test)
import WM


suite : Test
suite =
    describe "Game"
        [ msgTests ]


msgTests : Test
msgTests =
    describe "Msg"
        [ msgPerformActionTests
        , msgOnEventReceivedTests
        ]


msgPerformActionTests : Test
msgPerformActionTests =
    describe "PerformAction"
        [ describe "SwitchGateway"
            [ test "switches gateway and universe accordingly" <|
                \_ ->
                    let
                        -- We are initially at SP
                        initialState =
                            TM.state
                                |> TM.withUniverse Singleplayer

                        otherId =
                            ServerID.fromValue "other"

                        otherNip =
                            NIP.fromString "0@1.1.1.1"

                        -- We'll go to MP
                        msg =
                            PerformAction (SwitchGateway Multiplayer otherId otherNip)

                        ( newState, effect ) =
                            State.update msg initialState

                        newActiveUniverse =
                            State.getActiveUniverse newState
                    in
                    E.batch
                        [ -- Universe changed from SP to MP
                          E.equal initialState.currentUniverse Singleplayer
                        , E.equal newState.currentUniverse Multiplayer

                        -- `currentSession` is now pointing to the new server
                        , E.equal newState.currentSession (WM.toLocalSessionId otherId otherNip)

                        -- Active gateway has changed in the MP model
                        , E.equal newState.mp.activeGateway otherNip

                        -- Active gateway in the SP model remains unchanged
                        , E.equal newState.sp.activeGateway initialState.sp.activeGateway

                        -- No effects
                        , E.effectNone effect
                        ]
            ]
        ]


msgOnEventReceivedTests : Test
msgOnEventReceivedTests =
    describe "OnEventReceived"
        [ describe "Event.LogDeleted"
            [ test "flags the log as deleted" <|
                \_ ->
                    let
                        idxLog =
                            Mocks.idxLog

                        log =
                            TMLog.fromIndex idxLog

                        server =
                            TMServer.new
                                |> TMServer.withLogs [ log ]

                        gateway =
                            TMServer.gatewayFromServer server

                        game =
                            TM.game
                                |> TM.withServer server
                                |> TM.withGateway gateway

                        -- Initial state with a single log
                        initialState =
                            TM.state
                                |> TM.withGame game

                        logId =
                            LogID.fromValue idxLog.id

                        -- We'll simulate this log being deleted
                        logDeletedEv =
                            Mocks.logDeleted
                                |> Mocks.withLog_id logId

                        event =
                            Event.LogDeleted logDeletedEv initialState.currentUniverse

                        ( newState, effect ) =
                            State.update (OnEventReceived event) initialState

                        newLog =
                            newState
                                |> TM.getGame
                                |> TM.getServer server.nip
                                |> .logs
                                |> TMLog.getLog logId
                    in
                    E.batch
                        [ -- Initially, the log was not deleted
                          E.false log.isDeleted
                        , -- Now it is marked as deleted
                          E.true newLog.isDeleted
                        , E.effectNone effect
                        ]
            ]
        ]
