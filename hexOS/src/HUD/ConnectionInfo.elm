module HUD.ConnectionInfo exposing
    ( Model
    , Msg(..)
    , Selector(..)
    , initialModel
    , onWindowClose
    , onWindowCollapse
    , subscriptions
    , update
    , view
    )

import Browser.Events
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
import OS.CtxMenu as CtxMenu
import State exposing (State)
import UI exposing (UI, cl, col, div, id, row, text)
import UI.Icon
import WM



-- Types


type alias Model =
    { selector : Selector
    , isDropdownHovered : Bool
    , isSelectorHovered : Bool
    }


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
    | OnSelectorEnter
    | OnSelectorLeave
    | OnDropdownEnter
    | OnDropdownLeave
    | SwitchGateway Universe ServerID NIP
    | SwitchEndpoint Universe NIP
    | ToggleWMSession
    | ToOS OS.Bus.Action
    | NoOp



-- Model


initialModel : Model
initialModel =
    { selector = NoSelector
    , isDropdownHovered = False
    , isSelectorHovered = False
    }


onWindowClose : Model -> Model
onWindowClose model =
    { model | selector = NoSelector, isSelectorHovered = False }


onWindowCollapse : Model -> Model
onWindowCollapse model =
    { model | selector = NoSelector, isSelectorHovered = False }



-- Update


update : State -> Msg -> Model -> ( Model, Effect Msg )
update state msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )

        OpenSelector selector ->
            ( { model | selector = selector }, Effect.none )

        CloseSelector ->
            ( { model | selector = NoSelector, isSelectorHovered = False }, Effect.none )

        OnSelectorEnter ->
            ( { model | isSelectorHovered = True }, Effect.none )

        OnSelectorLeave ->
            ( { model | isSelectorHovered = False }, Effect.none )

        OnDropdownEnter ->
            ( { model | isDropdownHovered = True }, Effect.none )

        OnDropdownLeave ->
            ( { model | isDropdownHovered = False }, Effect.none )

        SwitchGateway universe gatewayId gatewayNip ->
            updateSwitchGateway state model universe gatewayId gatewayNip

        SwitchEndpoint universe endpointNip ->
            updateSwitchEndpoint model universe endpointNip

        ToggleWMSession ->
            ( model, Effect.msgToCmd <| ToOS <| OS.Bus.ToGame Game.ToggleWMSession )

        ToOS _ ->
            -- Handled by parent
            ( model, Effect.none )


updateSwitchGateway : State -> Model -> Universe -> ServerID -> NIP -> ( Model, Effect Msg )
updateSwitchGateway state model gtwUniverse gtwId gtwNip =
    let
        -- Always switch, except if the selected gateway is the activeGateway in the activeUniverse
        shouldSwitch =
            state.currentUniverse /= gtwUniverse || (State.getActiveGatewayNip state /= gtwNip)

        effect =
            if shouldSwitch then
                Effect.msgToCmd (ToOS (OS.Bus.ToGame (Game.SwitchGateway gtwUniverse gtwId gtwNip)))

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
    col
        [ addEvents model
        , CtxMenu.noopSelf NoOp
        ]
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
        , viewServerSelectorDropdown CIGateway model
        , viewServerSelectorDropdown CIEndpoint model
        , viewGatewayServer state model
        , viewVPNArea state model
        , viewEndpointServer state model
        ]


viewGatewayServer : State -> Model -> UI Msg
viewGatewayServer state _ =
    let
        game =
            State.getActiveUniverse state

        gateway =
            Game.getActiveGateway game

        canSwitchSession =
            not (WM.isSessionLocal state.currentSession)

        extraAttrs =
            if canSwitchSession then
                [ UI.pointer, UI.onClick ToggleWMSession ]

            else
                [ cl "hud-ci-server-active" ]
    in
    row (cl "hud-ci-server-area hud-ci-server-gateway" :: extraAttrs)
        [ text (NIP.getIPString gateway.nip) ]


viewEndpointServer : State -> Model -> UI Msg
viewEndpointServer state _ =
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

        canSwitchSession =
            isConnected && WM.isSessionLocal state.currentSession

        extraAttrs =
            if canSwitchSession then
                [ UI.onClick ToggleWMSession, cl "hud-ci-server-selectable" ]

            else
                [ cl "hud-ci-server-active" ]
    in
    row
        (cl "hud-ci-server-area hud-ci-server-endpoint" :: extraAttrs)
        [ text label ]


viewVPNArea : State -> Model -> UI Msg
viewVPNArea _ _ =
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
        activeServerClass =
            case side of
                CIGateway ->
                    "hud-ci-active-server-gateway"

                CIEndpoint ->
                    "hud-ci-active-server-endpoint"
    in
    div
        [ cl "hud-ci-active-server-indicator"
        , cl activeServerClass
        , cl "hud-ci-active-server-indicator-circle"
        ]
        []


viewServerSelectorDropdown : CISide -> Model -> UI Msg
viewServerSelectorDropdown side { selector } =
    let
        ( dropdownIconName, onClickMsg ) =
            case ( side, selector ) of
                ( CIGateway, SelectorGateway ) ->
                    -- "arrow_drop_up"
                    ( "keyboard_arrow_up", CloseSelector )

                ( CIGateway, _ ) ->
                    -- "arrow_drop_down"
                    ( "keyboard_arrow_down", OpenSelector SelectorGateway )

                ( CIEndpoint, SelectorEndpoint ) ->
                    -- "arrow_drop_up"
                    ( "keyboard_arrow_up", CloseSelector )

                ( CIEndpoint, _ ) ->
                    -- "arrow_drop_down"
                    ( "keyboard_arrow_down", OpenSelector SelectorEndpoint )

        dropdownIcon =
            UI.Icon.msOutline dropdownIconName Nothing
                |> UI.Icon.toUI

        selectorDropdownSide =
            case side of
                CIGateway ->
                    "hud-ci-srvselector-dropdown-gateway"

                CIEndpoint ->
                    "hud-ci-srvselector-dropdown-endpoint"
    in
    row
        [ cl "hud-ci-srvselector-dropdown"
        , cl selectorDropdownSide
        , UI.onClick onClickMsg
        , HE.onMouseEnter OnDropdownEnter
        , HE.onMouseLeave OnDropdownLeave
        ]
        [ dropdownIcon ]



-- Selector


viewSelector : State -> Model -> UI Msg
viewSelector state model =
    case model.selector of
        NoSelector ->
            UI.emptyEl

        SelectorGateway ->
            renderServerSelector CIGateway (viewGatewaySelector state model)

        SelectorEndpoint ->
            renderServerSelector CIEndpoint (viewEndpointSelector state model)


renderServerSelector : CISide -> UI Msg -> UI Msg
renderServerSelector side renderedSelector =
    let
        sideClass =
            case side of
                CIGateway ->
                    "hud-ci-srvselector-gateway"

                CIEndpoint ->
                    "hud-ci-srvselector-endpoint"
    in
    row
        [ id "hud-connection-info-srvselector"
        , cl sideClass
        , HE.onMouseEnter OnSelectorEnter
        , HE.onMouseLeave OnSelectorLeave
        ]
        [ renderedSelector ]


viewGatewaySelector : State -> Model -> UI Msg
viewGatewaySelector state _ =
    let
        spGateways =
            List.foldl (gatewaySelectorEntries Singleplayer) [] (Game.getGateways state.sp)

        mpGateways =
            List.foldl (gatewaySelectorEntries Multiplayer) [] (Game.getGateways state.mp)
    in
    col [ cl "hud-ci-selector-gateway-area" ] <|
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
            SwitchGateway gtwUniverse gateway.id gateway.nip

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



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    case ( model.selector, model.isSelectorHovered, model.isDropdownHovered ) of
        ( NoSelector, _, _ ) ->
            Sub.none

        ( _, False, False ) ->
            Browser.Events.onMouseDown (JD.succeed CloseSelector)

        _ ->
            Sub.none
