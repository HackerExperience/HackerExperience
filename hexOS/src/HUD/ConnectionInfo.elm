module HUD.ConnectionInfo exposing (Model, Msg, initialModel, update, view)

import Effect exposing (Effect)
import Game exposing (State)
import Game.Universe as Universe
import UI exposing (UI, cl, col, div, id, row, style, text)



-- Types


type alias Model =
    { selector : Selector }


type Selector
    = NoSelector
    | SelectorGateway
    | SelectorEndpoint


type Msg
    = OpenSelector Selector



-- Model


initialModel : Model
initialModel =
    { selector = NoSelector }



-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        OpenSelector selector ->
            ( { model | selector = selector }, Effect.none )



-- View


view : Game.State -> UI Msg
view state =
    row [ id "hud-connection-info" ]
        [ viewGatewayArea state
        , viewVpnArea
        , viewEndpointArea
        ]


viewGatewayArea : Game.State -> UI Msg
viewGatewayArea state =
    row [ cl "hud-ci-gateway-area" ]
        [ viewSideIcons
        , viewServer state
        ]


viewVpnArea : UI Msg
viewVpnArea =
    row [ cl "hud-ci-vpn-area" ]
        [ text "vpn" ]


viewEndpointArea : UI Msg
viewEndpointArea =
    row [ cl "hud-ci-endpoint-area" ]
        [ text "endp" ]


viewSideIcons : UI Msg
viewSideIcons =
    col [ cl "hud-ci-side-area" ]
        [ text "a"
        , text "b"
        ]


viewServer : Game.State -> UI Msg
viewServer state =
    col [ cl "hud-ci-server" ]
        [ text "Gateway"
        , case state.currentUniverse of
            Universe.Singleplayer ->
                text "SP"

            Universe.Multiplayer ->
                text "MP"
        , div
            [ cl "hud-ci-server-selector"
            , UI.pointer
            , UI.onClick <| OpenSelector SelectorGateway
            ]
            [ text "\\/" ]
        ]
