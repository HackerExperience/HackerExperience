module StateTest exposing (suite)

import Game.Bus exposing (Action(..))
import Game.Model.NIP as NIP
import Game.Msg exposing (Msg(..))
import Game.Universe as Universe exposing (Universe(..))
import State
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

                        otherNip =
                            NIP.fromString "0@1.1.1.1"

                        -- We'll go to MP
                        msg =
                            PerformAction (SwitchGateway Multiplayer otherNip)

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
                        , E.equal newState.currentSession (WM.toLocalSessionId otherNip)

                        -- Active gateway has changed in the MP model
                        , E.equal newState.mp.activeGateway otherNip

                        -- Active gateway in the SP model remains unchanged
                        , E.equal newState.sp.activeGateway initialState.sp.activeGateway

                        -- No effects
                        , E.effectNone effect
                        ]
            ]
        ]
