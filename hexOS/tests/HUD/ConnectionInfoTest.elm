module HUD.ConnectionInfoTest exposing (suite)

import Effect
import Game
import Game.Bus
import Game.Universe exposing (Universe(..))
import HUD.ConnectionInfo as CI exposing (Selector(..))
import OS
import OS.Bus
import TestHelpers.Expect as E
import TestHelpers.Game as TG
import TestHelpers.Models as TM
import TestHelpers.Random as TR
import TestHelpers.Test exposing (Test, describe, fuzzOnce, test, toFuzzer)


suite : Test
suite =
    describe "Msg"
        [ describe "OpenSelector"
            [ fuzzOnce (toFuzzer TR.hudCiSelector) "opens the selector" <|
                \selectorToOpen ->
                    let
                        initialModel =
                            TM.hudCi

                        msg =
                            CI.OpenSelector selectorToOpen

                        ( newModel, effect ) =
                            CI.update TM.state msg initialModel
                    in
                    E.batch
                        [ -- The model changed accordingly
                          E.notEqual newModel initialModel
                        , E.equal newModel { initialModel | selector = selectorToOpen }
                        , E.effectNone effect
                        ]
            ]
        , describe "CloseSelector"
            [ fuzzOnce (toFuzzer TR.hudCiSelector) "closes the selector" <|
                \currentlyOpenSelector ->
                    let
                        initialModel =
                            TM.hudCiWithSelector currentlyOpenSelector

                        msg =
                            CI.CloseSelector

                        ( newModel, effect ) =
                            CI.update TM.state msg initialModel
                    in
                    E.batch
                        [ -- Selector was open initially
                          E.equal initialModel.selector currentlyOpenSelector

                        -- But it got closed
                        , E.equal newModel { initialModel | selector = NoSelector }
                        , E.effectNone effect
                        ]
            ]
        , describe "SwitchGateway"
            [ test "requests Game.SwitchGateway (same universe but different serverIds)" <|
                \_ ->
                    let
                        ( state, model ) =
                            ( TM.state, TM.hudCiWithSelector SelectorGateway )

                        msg =
                            CI.SwitchGateway state.currentUniverse 999

                        ( newModel, effect ) =
                            CI.update state msg model
                    in
                    E.batch
                        [ -- We request (via Game.Bus) that the gateway is switched
                          E.effectMsgToCmd effect <|
                            CI.ToOS (OS.Bus.ToGame (Game.Bus.SwitchGateway Singleplayer 999))

                        -- The selector was closed
                        , E.notEqual model newModel
                        , E.equal newModel { model | selector = NoSelector }
                        ]
            , test "requests Game.SwitchGateway (same serverId but different gateway)" <|
                \_ ->
                    let
                        ( state, model ) =
                            ( TM.state, TM.hudCiWithSelector SelectorGateway )

                        gatewayId =
                            Game.getActiveGateway state

                        { otherUniverse } =
                            TG.universeInfo state

                        -- Same server ID but different universe
                        msg =
                            CI.SwitchGateway otherUniverse gatewayId

                        ( _, effect ) =
                            CI.update state msg model
                    in
                    E.batch
                        [ -- We request (via Game.Bus) that the gateway is switched
                          E.effectMsgToCmd effect <|
                            CI.ToOS (OS.Bus.ToGame (Game.Bus.SwitchGateway otherUniverse gatewayId))
                        ]
            ]
        , test "does not request Game.SwitchGateway if same server is selected" <|
            \_ ->
                let
                    ( state, model ) =
                        ( TM.state, TM.hudCiWithSelector SelectorGateway )

                    msg =
                        CI.SwitchGateway state.currentUniverse (Game.getActiveGateway state)

                    ( newModel, effect ) =
                        CI.update state msg model
                in
                E.batch
                    [ E.effectNone effect
                    , E.equal newModel { model | selector = NoSelector }
                    ]
        ]
