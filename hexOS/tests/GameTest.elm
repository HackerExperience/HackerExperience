module GameTest exposing (suite)

import Game
import Game.Bus exposing (Action(..))
import Game.Model.ServerID as ServerID
import Game.Msg exposing (Msg(..))
import Game.Universe as Universe exposing (Universe(..))
import TestHelpers.Expect as E
import TestHelpers.Game as TG
import TestHelpers.Models as TM
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
        [ msgPerformActionTests ]


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
                                |> TM.stateWithUniverse Singleplayer

                        serverId =
                            ServerID.fromValue 999

                        -- We'll go to MP
                        msg =
                            PerformAction (SwitchGateway Multiplayer serverId)

                        ( newState, effect ) =
                            Game.update msg initialState

                        newActiveUniverse =
                            Game.getActiveUniverse newState
                    in
                    E.batch
                        [ -- Universe changed from SP to MP
                          E.equal initialState.currentUniverse Singleplayer
                        , E.equal newState.currentUniverse Multiplayer

                        -- `currentSession` is now pointing to the new server
                        , E.equal newState.currentSession (WM.toLocalSessionId serverId)

                        -- Active gateway has changed in the MP model
                        , E.equal newState.mp.activeGateway serverId

                        -- Active gateway in the SP model remains unchanged
                        , E.equal newState.sp.activeGateway initialState.sp.activeGateway

                        -- No effects
                        , E.effectNone effect
                        ]
            ]
        ]
