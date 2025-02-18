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
import Game
import Game.Bus as Game
import Game.Model.NIP as NIP exposing (NIP)
import Game.Model.Server exposing (Gateway)
import Game.Model.ServerID exposing (ServerID)
import Game.Model.Tunnel exposing (Tunnel)
import Game.Universe as Universe exposing (Universe(..))
import Html.Events as HE
import Json.Decode as JD
import OS.Bus
import State exposing (State)
import UI exposing (UI, cl, col, div, id, row, text)
import UI.Icon
import WM



-- Types


type alias Model =
    { selector : Selector }


type Selector
    = NoSelector
    | SelectorGateway
    | SelectorEndpoint


{-| This type is exclusive for this module and is meant for enabling shared logic by defining which
"side" (i.e. Gateway or Endpoint) the function should implement. Sometimes the behaviour changes
slightly, but for the most part the implementation logic is shared/common.
-}
type CISide
    = CIGateway
    | CIEndpoint


type Msg
    = OpenSelector Selector
    | CloseSelector
    | SwitchGateway Universe ServerID
    | SwitchEndpoint Universe NIP
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

        SwitchEndpoint universe endpointNip ->
            updateSwitchEndpoint model universe endpointNip

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


updateSwitchEndpoint : Model -> Universe -> NIP -> ( Model, Effect Msg )
updateSwitchEndpoint model universe nip =
    ( { model | selector = NoSelector }
    , Effect.msgToCmd <| ToOS <| OS.Bus.ToGame (Game.SwitchEndpoint universe nip)
    )



-- View


view : State -> Model -> UI Msg
view state model =
    -- TODO: Figure out a better way to identify the top-level and each child (all 3 are important to identify)
    col [ addEvents model ]
        [ viewConnectionInfo state model
        , viewConnectionInfo2 state model
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
    let
        isLocalSession =
            WM.isSessionLocal state.currentSession

        side =
            if isLocalSession then
                CIGateway

            else
                CIEndpoint
    in
    row [ id "hud-connection-info" ]
        [ viewActiveServerIndicator side
        , viewSelectorDropdown CIGateway model
        , viewSelectorDropdown CIEndpoint model
        , viewGatewayServerNew state model
        , viewVPNAreaNew state model
        , viewEndpointServerNew state model
        ]


viewGatewayServerNew : State -> Model -> UI Msg
viewGatewayServerNew state model =
    let
        game =
            State.getActiveUniverse state

        gateway =
            Game.getActiveGateway game
    in
    row [ cl "hud-ci-server-area hud-ci-server-gateway" ]
        [ text (NIP.getIPString gateway.nip) ]


viewEndpointServerNew : State -> Model -> UI Msg
viewEndpointServerNew state model =
    row [ cl "hud-ci-server-area hud-ci-server-endpoint" ]
        [ text "93.84.190.205" ]


viewVPNAreaNew : State -> Model -> UI Msg
viewVPNAreaNew state model =
    let
        vpnIcon =
            UI.Icon.msOutline "public" Nothing
                |> UI.Icon.toUI
    in
    row [ cl "hud-ci-vpn-area" ]
        [ vpnIcon ]


viewActiveServerIndicator : CISide -> UI Msg
viewActiveServerIndicator side =
    let
        activeServerIcon =
            UI.Icon.msOutline "radio_button_checked" Nothing
                |> UI.Icon.toUI

        activeServerClass =
            case side of
                CIGateway ->
                    "hud-ci-active-server-gateway"

                CIEndpoint ->
                    "hud-ci-active-server-endpoint"
    in
    div [ cl "hud-ci-active-server-indicator", cl activeServerClass ]
        [ activeServerIcon ]


viewSelectorDropdown : CISide -> Model -> UI Msg
viewSelectorDropdown side { selector } =
    let
        dropdownIconName =
            case ( side, selector ) of
                ( CIGateway, SelectorGateway ) ->
                    -- "arrow_drop_up"
                    "keyboard_arrow_up"

                ( CIGateway, _ ) ->
                    -- "arrow_drop_down"
                    "keyboard_arrow_down"

                ( CIEndpoint, SelectorEndpoint ) ->
                    -- "arrow_drop_up"
                    "keyboard_arrow_up"

                ( CIEndpoint, _ ) ->
                    -- "arrow_drop_down"
                    "keyboard_arrow_down"

        dropdownIcon =
            UI.Icon.msOutline dropdownIconName Nothing
                |> UI.Icon.toUI

        selectorDropdownSide =
            case side of
                CIGateway ->
                    "hud-ci-selector-dropdown-gateway"

                CIEndpoint ->
                    "hud-ci-selector-dropdown-endpoint"

        hasNotification =
            case side of
                CIGateway ->
                    True

                CIEndpoint ->
                    False

        notificationClass =
            if hasNotification then
                "hud-ci-selector-dropdown-with-notification"

            else
                ""

        notificationIcon =
            if hasNotification then
                row [ cl "hud-ci-selector-dropdown-notification" ]
                    [ UI.Icon.msOutline "radio_button_checked" Nothing
                        |> UI.Icon.toUI
                    ]

            else
                UI.emptyEl
    in
    row [ cl "hud-ci-selector-dropdown", cl notificationClass, cl selectorDropdownSide ]
        [ dropdownIcon
        , notificationIcon
        ]


viewConnectionInfo2 : State -> Model -> UI Msg
viewConnectionInfo2 state model =
    row [ id "hud-connection-info2" ]
        [ viewGatewayArea state model
        , viewVpnArea
        , viewEndpointArea state model
        ]


viewGatewayArea : State -> Model -> UI Msg
viewGatewayArea state model =
    row [ cl "hud-ci-gateway-area2" ]
        [ viewSideIcons state CIGateway
        , viewGatewayServer state model
        ]


viewVpnArea : UI Msg
viewVpnArea =
    row [ cl "hud-ci-vpn-area2" ]
        [ text "vpn" ]


viewEndpointArea : State -> Model -> UI Msg
viewEndpointArea state model =
    row [ cl "hud-ci-endpoint-area2" ]
        [ viewEndpointServer state model
        , viewSideIcons state CIEndpoint
        ]


viewSideIcons : State -> CISide -> UI Msg
viewSideIcons { currentSession } side =
    let
        isLocalSession =
            WM.isSessionLocal currentSession

        isWMActive =
            case side of
                CIGateway ->
                    isLocalSession

                CIEndpoint ->
                    not isLocalSession

        wmIndicator =
            if isWMActive then
                "X"

            else
                " "
    in
    col [ cl "hud-ci-side-area2" ]
        [ text ("[" ++ wmIndicator ++ "]")
        , text "b"
        ]


{-| TODO: Once this module matures, try to merge the "mirrored" functions into a single one with
shared logic. An example can be found at `viewSideIcons`.
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

                SelectorEndpoint ->
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
    col [ cl "hud-ci-server-gateway2", UI.flexFill ]
        [ serverCol
        , div
            [ cl "hud-ci-server-selector2"
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
            state
                |> State.getActiveUniverse
                |> Game.getActiveEndpointNip

        ( label, isConnected ) =
            case endpoint of
                Just nip ->
                    ( NIP.getIPString nip, True )

                Nothing ->
                    ( "Not Connected", False )

        -- TODO: Hide selector switch if there are no tunnels
        ( arrowText, onClickMsg ) =
            case model.selector of
                NoSelector ->
                    ( text "\\/", OpenSelector SelectorEndpoint )

                SelectorGateway ->
                    ( text "\\/", OpenSelector SelectorEndpoint )

                _ ->
                    ( text "/\\", CloseSelector )

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
    col [ cl "hud-ci-server-endpoint2", UI.flexFill ]
        [ serverCol
        , div
            [ cl "hud-ci-server-selector2"
            , UI.pointer
            , UI.onClick onClickMsg

            -- Don't close the selector on "mousedown". We'll handle that ourselves.
            , stopPropagation "mousedown"
            ]
            [ arrowText ]
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
            renderSelector <| viewEndpointSelector state model


renderSelector : UI Msg -> UI Msg
renderSelector renderedSelector =
    row
        [ cl "hud-connection-info-selector2"
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
        spGateways =
            List.foldl (gatewaySelectorEntries Singleplayer) [] (Game.getGateways state.sp)

        mpGateways =
            List.foldl (gatewaySelectorEntries Multiplayer) [] (Game.getGateways state.mp)
    in
    col [] <|
        spGateways
            ++ mpGateways


viewEndpointSelector : State -> Model -> UI Msg
viewEndpointSelector state _ =
    let
        activeGame =
            State.getActiveUniverse state

        otherGame =
            State.getInactiveUniverse state

        gateway =
            Game.getActiveGateway activeGame

        activeEndpoint =
            Game.getActiveEndpointNip activeGame

        -- List of every tunnel within the active gateway
        gatewayTunnels =
            gateway.tunnels

        endpointsOnGateway =
            List.foldl (endpointSelectorEntries activeGame.universe activeEndpoint)
                []
                gatewayTunnels

        -- List of every tunnel in the Universe minus tunnels in active gateway
        universeTunnels =
            Game.getGateways activeGame
                |> List.concatMap (\{ tunnels } -> tunnels)
                |> List.filter (\{ sourceNip } -> sourceNip /= gateway.nip)

        endpointsOnUniverse =
            List.foldl (endpointSelectorEntries activeGame.universe Nothing)
                []
                universeTunnels

        otherUniverseSeparator =
            [ div [] [ text <| Universe.toString otherGame.universe ++ ":" ] ]

        -- List of every tunnel in the other universe
        otherUniverseTunnels =
            Game.getGateways otherGame
                |> List.concatMap (\{ tunnels } -> tunnels)

        endpointsOnOtherUniverse =
            List.foldl (endpointSelectorEntries otherGame.universe Nothing)
                []
                otherUniverseTunnels
    in
    col [] <|
        endpointsOnGateway
            ++ endpointsOnUniverse
            ++ otherUniverseSeparator
            ++ endpointsOnOtherUniverse


gatewaySelectorEntries : Universe -> Gateway -> List (UI Msg) -> List (UI Msg)
gatewaySelectorEntries gtwUniverse gateway acc =
    let
        onClickMsg =
            SwitchGateway gtwUniverse gateway.id

        label =
            case gtwUniverse of
                Singleplayer ->
                    "SP: " ++ NIP.getIPString gateway.nip

                Multiplayer ->
                    "MP: " ++ NIP.getIPString gateway.nip
    in
    div [ UI.pointer, UI.onClick onClickMsg ] [ text label ] :: acc


endpointSelectorEntries : Universe -> Maybe NIP -> Tunnel -> List (UI Msg) -> List (UI Msg)
endpointSelectorEntries universe activeEndpoint tunnel acc =
    let
        isCurrentEndpoint =
            case activeEndpoint of
                Just nip ->
                    nip == tunnel.targetNip

                Nothing ->
                    False

        onClickMsg =
            SwitchEndpoint universe tunnel.targetNip

        classes =
            if not isCurrentEndpoint then
                [ UI.pointer, UI.onClick onClickMsg ]

            else
                []

        label =
            NIP.getIPString tunnel.targetNip

        indicator =
            if isCurrentEndpoint then
                " <--"

            else
                ""
    in
    div classes [ text <| label ++ indicator ] :: acc


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
