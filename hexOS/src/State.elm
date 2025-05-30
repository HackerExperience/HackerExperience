module State exposing
    ( State
    , getActiveGatewayNip
    , getActiveUniverse
    , getInactiveUniverse
    , init
    , update
    )

import Effect exposing (Effect)
import Event exposing (Event)
import Game exposing (Model)
import Game.Bus exposing (Action(..))
import Game.Model.NIP exposing (NIP)
import Game.Msg exposing (Msg(..))
import Game.Universe exposing (Universe(..))
import WM



-- Types


type alias State =
    { sp : Model
    , mp : Model

    -- TODO: rename to `activeUniverse`
    , currentUniverse : Universe

    -- NOTE: The `currentSession` is a "bridge" between Game state and Client state. It is only here
    -- due to the SwitchGateway/SwitchEndpoint messages. I'll leave it here for now, but if that's
    -- the *only* reason WM state is used, consider moving it back to WM and duplicating these Msgs
    -- at HUD.ConnectionInfo. Another possibility is sending messages from Game to OS. This is not
    -- supported now, but I think it will likely be needed in the future. In any case, I'm delaying
    -- its implementation as much as possible.
    , currentSession : WM.SessionID
    }



-- Model


init : Universe -> WM.SessionID -> Model -> Model -> ( State, Effect Msg )
init currentUniverse currentSession spModel mpModel =
    ( { sp = spModel
      , mp = mpModel
      , currentUniverse = currentUniverse
      , currentSession = currentSession
      }
    , Effect.none
    )


getUniverse : State -> Universe -> Model
getUniverse state universe =
    case universe of
        Singleplayer ->
            state.sp

        Multiplayer ->
            state.mp


getActiveUniverse : State -> Model
getActiveUniverse state =
    case state.currentUniverse of
        Singleplayer ->
            state.sp

        Multiplayer ->
            state.mp


getInactiveUniverse : State -> Model
getInactiveUniverse state =
    case state.currentUniverse of
        Singleplayer ->
            state.mp

        Multiplayer ->
            state.sp


replaceUniverse : State -> Model -> Universe -> State
replaceUniverse state newModel universe =
    case universe of
        Singleplayer ->
            { state | sp = newModel }

        Multiplayer ->
            { state | mp = newModel }


replaceActiveUniverse : State -> Model -> State
replaceActiveUniverse state newUniverse =
    case state.currentUniverse of
        Singleplayer ->
            { state | sp = newUniverse }

        Multiplayer ->
            { state | mp = newUniverse }


switchUniverse : Universe -> State -> State
switchUniverse universe state =
    { state | currentUniverse = universe }


switchSession : WM.SessionID -> State -> State
switchSession sessionId state =
    { state | currentSession = sessionId }



-- Model > Universe API


getActiveGatewayNip : State -> NIP
getActiveGatewayNip state =
    (getActiveUniverse state).activeGateway


switchActiveGateway : NIP -> State -> State
switchActiveGateway newActiveGatewayNip state =
    state
        |> getActiveUniverse
        |> Game.switchActiveGateway newActiveGatewayNip
        |> replaceActiveUniverse state


switchActiveEndpoint : NIP -> State -> State
switchActiveEndpoint newActiveEndpointNip state =
    state
        |> getActiveUniverse
        |> Game.switchActiveEndpoint newActiveEndpointNip
        |> replaceActiveUniverse state



-- Update


update : Msg -> State -> ( State, Effect Msg )
update msg state =
    case msg of
        PerformAction action ->
            updateAction state action

        OnEventReceived event ->
            updateEvent state event

        NoOp ->
            ( state, Effect.none )


updateAction : State -> Action -> ( State, Effect Msg )
updateAction state action =
    case action of
        SwitchGateway universe nip ->
            let
                newState =
                    state
                        |> switchUniverse universe
                        |> switchActiveGateway nip
                        |> switchSession (WM.toLocalSessionId nip)
            in
            ( newState, Effect.none )

        SwitchEndpoint universe nip ->
            let
                newState =
                    state
                        |> switchUniverse universe
                        |> switchActiveEndpoint nip
                        |> switchSession (WM.toRemoteSessionId nip)
            in
            ( newState, Effect.none )

        ToggleWMSession ->
            let
                game =
                    getActiveUniverse state

                gateway =
                    Game.getActiveGateway game

                newSessionId =
                    case gateway.activeEndpoint of
                        Just endpointNip ->
                            WM.toggleSession game.activeGateway endpointNip state.currentSession

                        Nothing ->
                            state.currentSession
            in
            ( { state | currentSession = newSessionId }, Effect.none )

        ProcessOperation nip operation ->
            let
                game =
                    getActiveUniverse state

                newModel =
                    Game.handleProcessOperation game nip operation
            in
            ( replaceActiveUniverse state newModel, Effect.none )

        ActionNoOp ->
            ( state, Effect.none )


updateEvent : State -> Event -> ( State, Effect Msg )
updateEvent state event_ =
    case event_ of
        Event.LogDeleted event universe ->
            let
                game =
                    getUniverse state universe

                newModel =
                    Game.onLogDeletedEvent game event
            in
            ( replaceUniverse state newModel universe, Effect.none )

        Event.ProcessCompleted event universe ->
            let
                game =
                    getUniverse state universe

                ( newModel, action ) =
                    Game.onProcessCompletedEvent game event
            in
            ( replaceUniverse state newModel universe
            , Effect.msgToCmd <| PerformAction action
            )

        Event.ProcessCreated event universe ->
            let
                game =
                    getUniverse state universe

                newModel =
                    Game.onProcessCreatedEvent game event
            in
            ( replaceUniverse state newModel universe, Effect.none )

        Event.TunnelCreated event universe ->
            let
                game =
                    getUniverse state universe

                newModel =
                    Game.onTunnelCreatedEvent game event

                -- Switch the WM session to the new endpoint unless player is in a different gateway
                newState =
                    if (Game.getActiveGateway game).nip == event.source_nip then
                        state
                            |> switchSession (WM.toRemoteSessionId event.target_nip)

                    else
                        state
            in
            ( replaceUniverse newState newModel universe, Effect.none )

        -- This event is handled during BootState and should never hit this branch
        Event.IndexRequested _ _ ->
            ( state, Effect.none )
