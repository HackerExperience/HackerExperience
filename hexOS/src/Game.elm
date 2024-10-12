module Game exposing
    ( State
    , getActiveGateway
    , getActiveUniverse
    , init
    , update
    )

import Effect exposing (Effect)
import Game.Bus as Game exposing (Action(..))
import Game.Msg exposing (Msg(..))
import Game.Universe as Universe exposing (Universe(..))



-- Types


type alias State =
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


switchActiveGateway : Universe -> Int -> State -> State
switchActiveGateway universe newActiveGatewayId state =
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


updateAction : State -> Game.Action -> ( State, Effect Msg )
updateAction state action =
    case action of
        SwitchGateway universe gatewayId ->
            let
                newState =
                    state
                        |> switchUniverse universe
                        |> switchActiveGateway universe gatewayId
            in
            ( newState, Effect.none )

        ActionNoOp ->
            ( state, Effect.none )
