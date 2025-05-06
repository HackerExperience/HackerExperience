module Game exposing
    ( Model
    , buildApiContext
    , getActiveEndpointNip
    , getActiveGateway
    , getGateway
    , getGateways
    , getServer
    , init
    , onTunnelCreatedEvent
    , switchActiveEndpoint
    , switchActiveGateway
    )

import API.Events.Types as Events
import API.Types
import API.Utils
import Dict exposing (Dict)
import Dict.Extra as Dict
import Game.Model.NIP as NIP exposing (NIP, RawNIP)
import Game.Model.Server as Server exposing (Endpoint, Gateway, Server)
import Game.Model.Tunnel as Tunnel exposing (Tunnels)
import Game.Universe exposing (Universe(..))
import Maybe.Extra as Maybe


type alias Model =
    { universe : Universe
    , mainframeNip : NIP
    , activeGateway : NIP
    , gateways : Dict RawNIP Gateway
    , endpoints : Dict RawNIP Endpoint
    , apiCtx : API.Types.InputContext
    }



-- Model


init : API.Types.InputToken -> Universe -> Events.IndexRequested -> Model
init token universe index =
    { universe = universe
    , mainframeNip = index.player.mainframe_nip
    , activeGateway = index.player.mainframe_nip
    , gateways = Server.parseGateways index.player.gateways
    , endpoints = Server.parseEndpoints index.player.endpoints
    , apiCtx = buildApiContext token universe
    }


getServer : Model -> NIP -> Server
getServer model nip =
    Dict.get (NIP.toString nip) model.gateways
        |> Maybe.map .server
        |> Maybe.or (Dict.get (NIP.toString nip) model.endpoints |> Maybe.map .server)
        |> Maybe.withDefault Server.invalidServer


getGateway : Model -> NIP -> Gateway
getGateway model nip =
    Dict.get (NIP.toString nip) model.gateways
        |> Maybe.withDefault Server.invalidGateway


getGateways : Model -> List Gateway
getGateways model =
    Dict.values model.gateways


getActiveGateway : Model -> Gateway
getActiveGateway model =
    getGateway model model.activeGateway


getActiveEndpointNip : Model -> Maybe NIP
getActiveEndpointNip model =
    (getActiveGateway model).activeEndpoint


updateGateway : NIP -> (Gateway -> Gateway) -> Model -> Model
updateGateway nip updater model =
    let
        newGateways =
            Dict.update
                (NIP.toString nip)
                (Maybe.map (\gtw -> updater gtw))
                model.gateways
    in
    { model | gateways = newGateways }


updateActiveGateway : (Gateway -> Gateway) -> Model -> Model
updateActiveGateway updater model =
    updateGateway model.activeGateway updater model


switchActiveGateway : NIP -> Model -> Model
switchActiveGateway newActiveGatewayNip model =
    { model | activeGateway = newActiveGatewayNip }


{-| Switches the "activeEndpoint" entry. There's no guarantee that the `newActiveEndpointNip` is in
a tunnel from `activeGateway`, which is why we want to iterate over the existing tunnels and switch
the gateway if needed.
-}
switchActiveEndpoint : NIP -> Model -> Model
switchActiveEndpoint newActiveEndpointNip model =
    let
        tunnels =
            getAllTunnels model

        tunnel =
            Tunnel.findTunnelWithTargetNip tunnels newActiveEndpointNip

        gateway =
            case tunnel of
                Just { sourceNip } ->
                    findGatewayByNip model sourceNip

                Nothing ->
                    Server.invalidGateway
    in
    model
        |> switchActiveGateway gateway.nip
        |> updateActiveGateway (\gtw -> Server.switchActiveEndpoint gtw newActiveEndpointNip)



-- Model > Gateways


maybeFindGatewayByNip : Model -> NIP -> Maybe Gateway
maybeFindGatewayByNip model nip =
    -- TODO: No longer relevant since we now index gateways by nip
    Dict.find (\_ gtw -> gtw.nip == nip) model.gateways
        |> Maybe.map Tuple.second


{-| Returns the gateway with the corresponding NIP. This function assumes that the NIP will always
exist. If there is a possibility it won't, use the `maybeFindGatewayByNip` variant.
-}
findGatewayByNip : Model -> NIP -> Gateway
findGatewayByNip model nip =
    -- TODO: No longer relevant since we now index gateways by nip
    maybeFindGatewayByNip model nip
        |> Maybe.withDefault Server.invalidGateway



-- Model > Tunnels


getAllTunnels : Model -> Tunnels
getAllTunnels model =
    getGateways model
        |> List.concatMap (\{ tunnels } -> tunnels)



-- Event handlers


onTunnelCreatedEvent : Model -> Events.TunnelCreated -> Model
onTunnelCreatedEvent model event =
    let
        gateway =
            maybeFindGatewayByNip model event.source_nip

        updateGatewayFn =
            \model_ ->
                case gateway of
                    Just gtw ->
                        updateGateway gtw.nip (Server.onTunnelCreatedEvent event) model_

                    Nothing ->
                        model

        updateEndpointsFn =
            \model_ ->
                let
                    endpoint =
                        Server.parseEndpoint event.index

                    newEndpoints =
                        Dict.insert (NIP.toString endpoint.nip) endpoint model_.endpoints
                in
                { model_ | endpoints = newEndpoints }
    in
    model
        |> updateGatewayFn
        |> updateEndpointsFn



-- Utils


buildApiContext : API.Types.InputToken -> Universe -> API.Types.InputContext
buildApiContext token universe =
    let
        apiServer =
            case universe of
                Singleplayer ->
                    API.Types.ServerGameSP

                Multiplayer ->
                    API.Types.ServerGameMP
    in
    API.Utils.buildContext (Just token) apiServer
