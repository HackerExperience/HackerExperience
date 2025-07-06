module HUD.ConnectionInfoTest exposing (suite)

import Effect
import Game.Bus
import Game.Model.NIP as NIP
import Game.Model.ServerID as ServerID
import Game.Universe exposing (Universe(..))
import HUD.ConnectionInfo as CI exposing (Selector(..))
import OS
import OS.Bus
import State
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
            [ test "requests Game.SwitchGateway (same universe but different nips)" <|
                \_ ->
                    let
                        ( state, model ) =
                            ( TM.state, TM.hudCiWithSelector SelectorGateway )

                        otherId =
                            ServerID.fromValue "other"

                        otherNip =
                            NIP.fromString "0@2.2.2.2"

                        msg =
                            CI.SwitchGateway state.currentUniverse otherId otherNip

                        ( newModel, effect ) =
                            CI.update state msg model
                    in
                    E.batch
                        [ -- We request (via Game.Bus) that the gateway is switched
                          E.effectMsgToCmd effect <|
                            CI.ToOS
                                (OS.Bus.ToGame
                                    (Game.Bus.SwitchGateway Singleplayer otherId otherNip)
                                )

                        -- The selector was closed
                        , E.notEqual model newModel
                        , E.equal newModel { model | selector = NoSelector }
                        ]
            , test "requests Game.SwitchGateway (same NIP but different gateway)" <|
                \_ ->
                    let
                        ( state, model ) =
                            ( TM.state, TM.hudCiWithSelector SelectorGateway )

                        gtwId =
                            ServerID.fromValue "gtwid"

                        gtwNip =
                            State.getActiveGatewayNip state

                        { otherUniverse } =
                            TG.universeInfo state

                        -- Same server NIP but different universe
                        msg =
                            CI.SwitchGateway otherUniverse gtwId gtwNip

                        ( _, effect ) =
                            CI.update state msg model
                    in
                    E.batch
                        [ -- We request (via Game.Bus) that the gateway is switched
                          E.effectMsgToCmd effect <|
                            CI.ToOS
                                (OS.Bus.ToGame (Game.Bus.SwitchGateway otherUniverse gtwId gtwNip))
                        ]
            ]
        , test "does not request Game.SwitchGateway if same server is selected" <|
            \_ ->
                let
                    ( state, model ) =
                        ( TM.state, TM.hudCiWithSelector SelectorGateway )

                    gtwId =
                        ServerID.fromValue "gtwid"

                    gtwNip =
                        State.getActiveGatewayNip state

                    msg =
                        CI.SwitchGateway state.currentUniverse gtwId gtwNip

                    ( newModel, effect ) =
                        CI.update state msg model
                in
                E.batch
                    [ E.effectNone effect
                    , E.equal newModel { model | selector = NoSelector }
                    ]
        ]
