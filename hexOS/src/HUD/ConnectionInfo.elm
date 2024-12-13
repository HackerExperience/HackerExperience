module HUD.ConnectionInfo exposing
    ( Model
    , Msg(..)
    , Selector(..)
    , addGlobalEvents
    , initialModel
    , update
    , view
    )

import Effect exposing (Effect)
import Game as State exposing (State)
import Game.Bus as Game
import Game.Model as Game
import Game.Model.NIP as NIP
import Game.Model.ServerID as ServerID exposing (ServerID)
import Game.Universe as Universe exposing (Universe(..))
import Html.Events as HE
import Json.Decode as JD
import OS.Bus
import UI exposing (UI, cl, col, div, id, row, text)
import WM



-- Types


type alias Model =
    { selector : Selector }


type Selector
    = NoSelector
    | SelectorGateway
    | SelectorEndpoint


type Msg
    = OpenSelector Selector
    | CloseSelector
    | SwitchGateway Universe ServerID
    | ToggleWMSession
    | ToOS OS.Bus.Action
    | NoOp



-- Model


initialModel : Model
initialModel =
    { selector = NoSelector }



-- Update


update : State -> Msg -> Model -> ( Model, Effect Msg )
update state msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )

        OpenSelector selector ->
            ( { model | selector = selector }, Effect.none )

        CloseSelector ->
            ( { model | selector = NoSelector }, Effect.none )

        SwitchGateway universe gatewayId ->
            updateSwitchGateway state model universe gatewayId

        ToggleWMSession ->
            ( model, Effect.msgToCmd <| ToOS <| OS.Bus.ToGame Game.ToggleWMSession )

        ToOS _ ->
            -- Handled by parent
            ( model, Effect.none )


updateSwitchGateway : State -> Model -> Universe -> ServerID -> ( Model, Effect Msg )
updateSwitchGateway state model gtwUniverse gatewayId =
    let
        -- Always switch, except if the selected gateway is the activeGateway in the activeUniverse
        shouldSwitch =
            state.currentUniverse /= gtwUniverse || (State.getActiveGatewayId state /= gatewayId)

        effect =
            if shouldSwitch then
                Effect.msgToCmd <| ToOS <| OS.Bus.ToGame (Game.SwitchGateway gtwUniverse gatewayId)

            else
                Effect.none
    in
    ( { model | selector = NoSelector }, effect )



-- View


view : State -> Model -> UI Msg
view state model =
    -- TODO: Figure out a better way to identify the top-level and each child (all 3 are important to identify)
    col [ addEvents model ]
        [ viewConnectionInfo state model
        , viewSelector state model
        ]


addEvents : Model -> UI.Attribute Msg
addEvents model =
    case model.selector of
        NoSelector ->
            UI.emptyAttr

        _ ->
            -- HE.onMouseUp CloseSelector
            UI.emptyAttr


viewConnectionInfo : State -> Model -> UI Msg
viewConnectionInfo state model =
    row [ id "hud-connection-info" ]
        [ viewGatewayArea state model
        , viewVpnArea
        , viewEndpointArea state model
        ]


viewGatewayArea : State -> Model -> UI Msg
viewGatewayArea state model =
    row [ cl "hud-ci-gateway-area" ]
        [ viewSideIcons
        , viewGatewayServer state model
        ]


viewVpnArea : UI Msg
viewVpnArea =
    row [ cl "hud-ci-vpn-area" ]
        [ text "vpn" ]


viewEndpointArea : State -> Model -> UI Msg
viewEndpointArea state model =
    row [ cl "hud-ci-endpoint-area" ]
        [ viewEndpointServer state model
        , viewSideIcons

        -- text "endp"
        ]


viewSideIcons : UI Msg
viewSideIcons =
    col [ cl "hud-ci-side-area" ]
        [ text "[X]"
        , text "b"
        ]


{-| TODO: Once this module matures, try to merge the "mirrored" functions into a single one with
shared logic.
-}
viewGatewayServer : State -> Model -> UI Msg
viewGatewayServer state model =
    let
        game =
            State.getActiveUniverse state

        gateway =
            Game.getActiveGateway game

        ( arrowText, onClickMsg ) =
            case model.selector of
                NoSelector ->
                    ( text "\\/", OpenSelector SelectorGateway )

                _ ->
                    ( text "/\\", CloseSelector )

        canSwitchSession =
            not (WM.isSessionLocal state.currentSession)

        serverClasses =
            if canSwitchSession then
                [ UI.pointer, UI.onClick ToggleWMSession ]

            else
                []

        serverCol =
            col serverClasses
                [ text "Gatewayy"
                , text (NIP.getIPString gateway.nip)
                ]
    in
    col [ cl "hud-ci-server-gateway", UI.flexFill ]
        [ serverCol
        , div
            [ cl "hud-ci-server-selector"
            , UI.pointer
            , UI.onClick onClickMsg

            -- Don't close the selector on "mousedown". We'll handle that ourselves.
            , stopPropagation "mousedown"
            ]
            [ arrowText ]
        ]


viewEndpointServer : State -> Model -> UI Msg
viewEndpointServer state model =
    let
        endpoint =
            State.getActiveEndpointNip state

        ( label, isConnected ) =
            case endpoint of
                Just nip ->
                    ( NIP.getIPString nip, True )

                Nothing ->
                    ( "Not Connected", False )

        canSwitchSession =
            isConnected && WM.isSessionLocal state.currentSession

        serverClasses =
            if canSwitchSession then
                [ UI.pointer, UI.onClick ToggleWMSession ]

            else
                []

        serverCol =
            col serverClasses
                [ text "Endpoint"
                , text label
                ]
    in
    col [ cl "hud-ci-server-endpoint", UI.flexFill ]
        [ serverCol
        , div [ cl "hud-ci-server-selector" ]
            [ text "\\/*" ]
        ]



-- Selector


viewSelector : State -> Model -> UI Msg
viewSelector state model =
    case model.selector of
        NoSelector ->
            UI.emptyEl

        SelectorGateway ->
            renderSelector <| viewGatewaySelector state model

        SelectorEndpoint ->
            text "todo"


renderSelector : UI Msg -> UI Msg
renderSelector renderedSelector =
    row
        [ cl "hud-connection-info-selector"
        , stopPropagation "mousedown"
        ]
        [ renderedSelector ]



-- TODO: stopPropagation should be a util (also used in OS)


stopPropagation : String -> UI.Attribute Msg
stopPropagation event =
    HE.stopPropagationOn event
        (JD.succeed <| (\msg -> ( msg, True )) NoOp)


viewGatewaySelector : State -> Model -> UI Msg
viewGatewaySelector state model__ =
    let
        -- TODO: feed the list of gateways directly from State
        spGateways =
            List.foldl (gatewaySelectorEntries state Singleplayer) [] [ ServerID.fromValue 1 ]

        mpGateways =
            List.foldl (gatewaySelectorEntries state Multiplayer) [] [ ServerID.fromValue 9 ]
    in
    col [] <|
        spGateways
            ++ mpGateways


gatewaySelectorEntries : State -> Universe -> ServerID -> List (UI Msg) -> List (UI Msg)
gatewaySelectorEntries state__ gtwUniverse serverId acc__ =
    -- TODO: Use acc
    let
        onClickMsg =
            SwitchGateway gtwUniverse serverId

        label =
            case gtwUniverse of
                Singleplayer ->
                    "SP " ++ String.fromInt (ServerID.toValue serverId)

                Multiplayer ->
                    "MP " ++ String.fromInt (ServerID.toValue serverId)
    in
    [ div [ UI.onClick onClickMsg ] [ text label ] ]


addGlobalEvents : Model -> List (UI.Attribute Msg)
addGlobalEvents model =
    case model.selector of
        NoSelector ->
            []

        -- If there's a Selector open, we want any "mousedown" outside it to automatically close it.
        -- In order to achieve the "outside it" part, we need to `stopPropagation "mousedown"` in
        -- some parts, as can be seen in this file.
        -- One issue is that other parts of the application that also stop the propagation of
        -- `mousedown` end up affecting the usability here. One such example is clicking in the "X"
        -- icon to close a window. Try that out: the experience is not great, and I don't yet have
        -- a solution for this problem.
        _ ->
            [ HE.on "mousedown" <| JD.succeed CloseSelector ]
