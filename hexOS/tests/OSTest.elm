module OSTest exposing (suite)

import Apps.Input as App exposing (InitialInput(..))
import Apps.Manifest as App
import Apps.Types as Apps
import Dict
import Effect
import Game.Universe as Universe
import OS exposing (Msg(..))
import OS.AppID exposing (AppID)
import OS.Bus as Bus
import OS.CtxMenu as CtxMenu
import Program exposing (program)
import ProgramTest as PT
import State exposing (State)
import TestHelpers.Expect as E
import TestHelpers.Models as TM
import TestHelpers.Test exposing (Test, describe, test)
import WM


suite : Test
suite =
    describe "OS"
        [ msgTests
        ]


msgTests : Test
msgTests =
    describe "Msg"
        [ msgPerformActionTests
        , msgDragTests
        ]


msgPerformActionTests : Test
msgPerformActionTests =
    describe "PerformAction"
        [ describe "RequestOpenApp"
            [ test "returns Bus.OpenApp action by default" <|
                \_ ->
                    let
                        msg =
                            PerformAction (Bus.RequestOpenApp App.DemoApp Nothing EmptyInput)

                        ( newModel, effect ) =
                            OS.update TM.state msg TM.os
                    in
                    E.batch
                        [ -- Unless told otherwise, RequestOpenApp gets the approval to OpenApp
                          E.effectMsgToCmd effect
                            (PerformAction (Bus.OpenApp App.DemoApp Nothing EmptyInput))

                        -- Model remains unchanged
                        , E.equal TM.os newModel
                        ]
            ]
        , describe "RequestCloseApp"
            [ test "returns Bus.CloseApp action by default" <|
                \_ ->
                    let
                        ( initialModel, appId ) =
                            TM.osWithApp TM.os

                        ( newModel, effect ) =
                            OS.update TM.state (PerformAction (Bus.RequestCloseApp appId)) initialModel
                    in
                    E.batch
                        [ -- Got approval to CloseApp
                          E.effectMsgToCmd effect <| PerformAction (Bus.CloseApp appId)

                        -- Model remains unchanged
                        , E.equal newModel initialModel
                        ]
            ]
        , describe "RequestFocusApp"
            [ test "returns Bus.FocusApp action by default" <|
                \_ ->
                    let
                        ( initialModel, appId ) =
                            TM.osWithApp TM.os

                        ( newModel, effect ) =
                            OS.update TM.state (PerformAction (Bus.RequestFocusApp appId)) initialModel
                    in
                    E.batch
                        [ -- Got approval to FocusApp
                          E.effectMsgToCmd effect <| PerformAction (Bus.FocusApp appId)

                        -- Model remains unchanged
                        , E.equal newModel initialModel
                        ]
            ]
        , describe "OpenApp"
            [ test "updates model accordingly" <|
                \_ ->
                    let
                        msg =
                            PerformAction (Bus.OpenApp App.DemoApp Nothing EmptyInput)

                        appId =
                            TM.os.wm.nextAppId

                        ( newModel, _ ) =
                            OS.update TM.state msg TM.os
                    in
                    E.batch
                        [ -- App Model is stored somewhere
                          let
                            appModel =
                                Maybe.withDefault Apps.InvalidModel <| Dict.get appId newModel.appModels
                          in
                          E.equal appModel <| Apps.DemoModel { appId = appId, count = 0 }

                        -- The wm.windows list has changed
                        , let
                            window =
                                WM.getWindow newModel.wm.windows appId
                          in
                          E.batch
                            [ -- This is not meant to be an exhaustive assertion; use WMTest for that
                              E.equal window.appId appId
                            , E.equal window.app App.DemoApp
                            , E.equal window.zIndex TM.os.wm.nextZIndex
                            , E.true window.isVisible
                            , E.false window.isPopup
                            , E.nothing window.parent
                            ]

                        -- nextAppId is updated
                        , E.equal newModel.wm.nextAppId <| TM.os.wm.nextAppId + 1

                        -- nextZIndex is updated
                        , E.equal newModel.wm.nextZIndex <| TM.os.wm.nextZIndex + 1

                        -- Newly opened window is focused by default
                        , assertFocusedWindow newModel.wm TM.state (Just appId)
                        ]
            ]
        , describe "CloseApp"
            [ test "updates model accordingly" <|
                \_ ->
                    let
                        ( preModel1, appId1 ) =
                            TM.osWithApp TM.os

                        ( initialModel, appId2__ ) =
                            TM.osWithApp preModel1

                        ( newModel, effect ) =
                            OS.update TM.state (PerformAction (Bus.CloseApp appId1)) initialModel
                    in
                    E.batch
                        [ -- Initial model has two apps / windows
                          E.dictHasKey initialModel.appModels 1
                        , E.dictHasKey initialModel.appModels 2
                        , E.dictHasKey initialModel.wm.windows 1
                        , E.dictHasKey initialModel.wm.windows 2

                        -- After we closed app 1, it is gone, but 2 is unaffected
                        , E.notDictHasKey newModel.appModels 1
                        , E.dictHasKey newModel.appModels 2
                        , E.notDictHasKey newModel.wm.windows 1
                        , E.dictHasKey newModel.wm.windows 2

                        -- Initial model was originally focused on 2 and now isn't focused
                        , assertFocusedWindow initialModel.wm TM.state (Just 2)

                        -- NOTE: This test originally asserted that app 2 remained focused even
                        -- after closing the other app. This is doable, but I fail to see a clear
                        -- benefit. We can always revert this change if needed.
                        , assertFocusedWindow newModel.wm TM.state Nothing

                        -- When closing a window, we also relay a Close message to the CtxMenu; this
                        -- is needed due to "stopPropagations" around header actions
                        , let
                            expectedEffect =
                                Effect.msgToCmd <| PerformAction (Bus.ToCtxMenu CtxMenu.Close)
                          in
                          E.effectContains effect expectedEffect
                        ]
            , test "closing a focused window marks it as unfocused" <|
                \_ ->
                    let
                        ( initialModel, appId ) =
                            TM.osWithApp TM.os

                        ( newModel, _ ) =
                            OS.update TM.state (PerformAction (Bus.CloseApp appId)) initialModel
                    in
                    E.batch
                        [ -- Initially, app 1 was focused. Now it's no longer focused
                          assertFocusedWindow initialModel.wm TM.state (Just 1)
                        , assertFocusedWindow newModel.wm TM.state Nothing
                        ]
            ]
        , describe "FocusApp"
            [ test "updates model accordingly" <|
                \_ ->
                    let
                        ( preModel1, appId1 ) =
                            TM.osWithApp TM.os

                        ( initialModel, appId2 ) =
                            TM.osWithApp preModel1

                        ( newModel, effect ) =
                            OS.update TM.state (PerformAction (Bus.FocusApp appId1)) initialModel
                    in
                    E.batch
                        [ -- Initially, `appId2` window was focused
                          assertFocusedWindow initialModel.wm TM.state (Just appId2)

                        -- After our message, `appId1` became focused
                        , assertFocusedWindow newModel.wm TM.state (Just appId1)
                        , E.effectNone effect
                        ]
            ]
        ]


msgDragTests : Test
msgDragTests =
    describe "Drag (StartDrag/Drag/StopDrag)"
        [ describe "StartDrag"
            [ test "starts draging the app" <|
                \_ ->
                    let
                        ( initialModel, appId ) =
                            TM.osWithApp TM.os

                        ( newModel, effect ) =
                            OS.update TM.state (StartDrag appId 50 51) initialModel
                    in
                    E.batch
                        [ -- The `wm.dragging` value was set
                          E.just newModel.wm.dragging

                        -- It contains apparently correct values (proper testing is at WMTest)
                        , let
                            ( draggingAppId, cX, cY ) =
                                case newModel.wm.dragging of
                                    Just ( appId_, _, ( cX_, cY_ ) ) ->
                                        ( appId_, cX_, cY_ )

                                    Nothing ->
                                        ( 0, 0, 0 )
                          in
                          E.batch
                            [ E.equal draggingAppId appId
                            , E.equal cX 50
                            , E.equal cY 51
                            ]
                        , E.effectNone effect
                        ]
            ]
        , describe "Drag"
            [ test "changes the window position" <|
                \_ ->
                    let
                        ( initialModel, appId ) =
                            TM.osWithApp TM.os

                        ( draggingModel, _ ) =
                            OS.update TM.state (StartDrag appId 50 51) initialModel

                        ( newModel, effect ) =
                            OS.update TM.state (Drag 60 66) draggingModel
                    in
                    E.batch
                        [ let
                            windowBefore =
                                WM.getWindow draggingModel.wm.windows appId

                            windowAfter =
                                WM.getWindow newModel.wm.windows appId
                          in
                          E.batch
                            [ -- Both posX and posY have changed
                              E.notEqual windowBefore.posX windowAfter.posX
                            , E.notEqual windowBefore.posY windowAfter.posY

                            -- More specifically, the positions have changed by exactly the delta
                            -- between the StartDrag position (50/51) and the Drag position (60/65),
                            -- which is (10/15)
                            , E.equal windowAfter.posX (windowBefore.posX + 10)
                            , E.equal windowAfter.posY (windowBefore.posY + 15)
                            ]
                        , E.effectNone effect
                        ]

            -- TODO: Test it does not exceed the viewport
            ]
        , describe "StopDrag"
            [ test "flags the window as no longer dragging" <|
                \_ ->
                    let
                        ( initialModel, appId ) =
                            TM.osWithApp TM.os

                        ( draggingModel, _ ) =
                            OS.update TM.state (StartDrag appId 50 51) initialModel

                        ( newModel, effect ) =
                            OS.update TM.state StopDrag draggingModel
                    in
                    E.batch
                        [ -- The draggingModel was dragging
                          E.just draggingModel.wm.dragging

                        -- But the newModel isn't
                        , E.nothing newModel.wm.dragging
                        , E.effectNone effect
                        ]
            , test "performs a no-op if no windows are dragging" <|
                \_ ->
                    let
                        ( newModel, effect ) =
                            OS.update TM.state StopDrag TM.os
                    in
                    E.batch
                        [ -- Nada changed
                          E.nothing TM.os.wm.dragging
                        , E.nothing newModel.wm.dragging
                        , E.effectNone effect
                        ]
            ]
        ]


assertFocusedWindow : WM.Model -> State -> Maybe AppID -> E.Expectation
assertFocusedWindow wm state expectedAppId =
    let
        focusedWindowOnSession =
            Dict.get (WM.sessionIdToString state.currentSession) wm.focusedWindows
                |> Maybe.withDefault Nothing
    in
    E.equal focusedWindowOnSession expectedAppId
