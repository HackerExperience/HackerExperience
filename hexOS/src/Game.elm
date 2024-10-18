module Game exposing
    ( State
    , getActiveGateway
    , getActiveUniverse
    , getInactiveUniverse
    , init
    , update
    )

import Effect exposing (Effect)
import Game.Bus exposing (Action(..))
import Game.Msg exposing (Msg(..))
import Game.Universe as Universe exposing (Universe(..))



-- Types


type alias State =
    -- TODO: Rethink "Universe" vs "Universe.Model". Sometimes they are both referred to as simply
    -- "universe" but that won't play well in the long term. Maybe UniverseId?
    { sp : Universe.Model
    , mp : Universe.Model

    -- TODO: rename to `activeUniverse`
    , currentUniverse : Universe
    }



-- Model


init : Universe -> Universe.Model -> Universe.Model -> ( State, Effect Msg )
init currentUniverse spModel mpModel =
    ( { sp = spModel
      , mp = mpModel
      , currentUniverse = currentUniverse
      }
    , Effect.none
    )


getActiveUniverse : State -> Universe.Model
getActiveUniverse state =
    case state.currentUniverse of
        Singleplayer ->
            state.sp

        Multiplayer ->
            state.mp


getInactiveUniverse : State -> Universe.Model
getInactiveUniverse state =
    case state.currentUniverse of
        Singleplayer ->
            state.mp

        Multiplayer ->
            state.sp


replaceActiveUniverse : State -> Universe.Model -> State
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


getActiveGateway : State -> Int
getActiveGateway state =
    (getActiveUniverse state).activeGateway


switchActiveGateway : Int -> State -> State
switchActiveGateway newActiveGatewayId state =
    state
        |> getActiveUniverse
        |> Universe.switchActiveGateway newActiveGatewayId
        |> replaceActiveUniverse state



-- Update


update : Msg -> State -> ( State, Effect Msg )
update msg state =
    case msg of
        PerformAction action ->
            updateAction state action

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
