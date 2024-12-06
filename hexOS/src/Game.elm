module Game exposing
    ( State
    , getActiveGateway
    , getActiveUniverse
    , getInactiveUniverse
    , init
    , update
    )

import Effect exposing (Effect)
import Event exposing (Event)
import Game.Bus exposing (Action(..))
import Game.Model as Model exposing (Model)
import Game.Model.ServerID exposing (ServerID)
import Game.Msg exposing (Msg(..))
import Game.Universe exposing (Universe(..))



-- Types


type alias State =
    { sp : Model
    , mp : Model

    -- TODO: rename to `activeUniverse`
    , currentUniverse : Universe
    }



-- Model


init : Universe -> Model -> Model -> ( State, Effect Msg )
init currentUniverse spModel mpModel =
    ( { sp = spModel
      , mp = mpModel
      , currentUniverse = currentUniverse
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



-- Model > Universe API


getActiveGateway : State -> ServerID
getActiveGateway state =
    (getActiveUniverse state).activeGateway


switchActiveGateway : ServerID -> State -> State
switchActiveGateway newActiveGatewayId state =
    state
        |> getActiveUniverse
        |> Model.switchActiveGateway newActiveGatewayId
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
        SwitchGateway universe gatewayId ->
            let
                newState =
                    state
                        |> switchUniverse universe
                        |> switchActiveGateway gatewayId
            in
            ( newState, Effect.none )

        ActionNoOp ->
            ( state, Effect.none )


updateEvent : State -> Event -> ( State, Effect Msg )
updateEvent state event_ =
    case event_ of
        Event.TunnelCreated event universe ->
            let
                newModel =
                    Model.onTunnelCreatedEvent (getUniverse state universe) event
            in
            ( replaceUniverse state newModel universe, Effect.none )

        -- This event is handled during BootState and should never hit this branch
        Event.IndexRequested _ _ ->
            ( state, Effect.none )
