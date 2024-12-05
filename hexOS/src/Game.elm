module Game exposing
    ( State
    , getActiveGateway
    , getActiveUniverse
    , getInactiveUniverse
    , init
    , update
    )

import API.Events.Types as Events
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
            onTunnelCreatedEvent state (getUniverse state universe) event

        -- This event is handled during BootState and should never hit this branch
        Event.IndexRequested _ _ ->
            ( state, Effect.none )


onTunnelCreatedEvent : State -> Model -> Events.TunnelCreated -> ( State, Effect Msg )
onTunnelCreatedEvent state model event =
    ( state, Effect.none )
