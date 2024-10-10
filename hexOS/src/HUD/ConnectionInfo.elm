module HUD.ConnectionInfo exposing
    ( Model
    , Msg(..)
    , addGlobalEvents
    , initialModel
    , update
    , view
    )

import Effect exposing (Effect)
import Game exposing (State)
import Game.Universe as Universe
import Html.Events as HE
import Json.Decode as JD
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
    | CloseSelector
    | NoOp



-- Model


initialModel : Model
initialModel =
    { selector = NoSelector }



-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )

        OpenSelector selector ->
            ( { model | selector = selector }, Effect.none )

        CloseSelector ->
            ( { model | selector = NoSelector }, Effect.none )



-- View


view : Game.State -> Model -> UI Msg
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


viewConnectionInfo : Game.State -> Model -> UI Msg
viewConnectionInfo state model =
    row [ id "hud-connection-info" ]
        [ viewGatewayArea state model
        , viewVpnArea
        , viewEndpointArea
        ]


viewGatewayArea : Game.State -> Model -> UI Msg
viewGatewayArea state model =
    row [ cl "hud-ci-gateway-area" ]
        [ viewSideIcons
        , viewServer state model
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


viewServer : Game.State -> Model -> UI Msg
viewServer state model =
    let
        ( arrowText, onClickMsg ) =
            case model.selector of
                NoSelector ->
                    ( text "\\/", OpenSelector SelectorGateway )

                _ ->
                    ( text "/\\", CloseSelector )
    in
    col [ cl "hud-ci-server", UI.flexFill ]
        [ text "Gateway"
        , case state.currentUniverse of
            Universe.Singleplayer ->
                text "SP"

            Universe.Multiplayer ->
                text "MP"
        , div
            [ cl "hud-ci-server-selector"
            , UI.pointer
            , UI.onClick <| onClickMsg

            -- Don't close the selector on "mousedown". We'll handle that ourselves.
            , stopPropagation "mousedown"
            ]
            [ arrowText ]
        ]



-- Selector


viewSelector : Game.State -> Model -> UI Msg
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


viewGatewaySelector : Game.State -> Model -> UI Msg
viewGatewaySelector state model =
    col []
        [ text "foo"
        , div [ UI.onClick (OpenSelector SelectorGateway) ] [ text "click me " ]
        ]


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
            [ HE.on "mousedown" <| JD.succeed <| CloseSelector ]
