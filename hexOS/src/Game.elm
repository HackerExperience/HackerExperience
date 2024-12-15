module Game exposing
    ( Model
    , buildApiContext
    , getActiveEndpointNip
    , getActiveGateway
    , getGateway
    , getGateways
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
import Game.Model.NIP exposing (NIP, RawNIP)
import Game.Model.Server as Server exposing (Endpoint, Gateway)
import Game.Model.ServerID as ServerID exposing (RawServerID, ServerID)
import Game.Model.Tunnel as Tunnel exposing (Tunnels)
import Game.Universe exposing (Universe(..))


type alias Model =
    { universe : Universe
    , mainframeID : ServerID
    , activeGateway : ServerID
    , gateways : Dict RawServerID Gateway
    , endpoints : Dict RawNIP Endpoint
    , apiCtx : API.Types.InputContext
    }



-- Model


init : API.Types.InputToken -> Universe -> Events.IndexRequested -> Model
init token universe index =
    { universe = universe
    , mainframeID = index.player.mainframe_id
    , activeGateway = index.player.mainframe_id
    , gateways = Server.parseGateways index.player.gateways
    , endpoints = Dict.empty
    , apiCtx = buildApiContext token universe
    }


getGateway : Model -> ServerID -> Gateway
getGateway model gatewayId =
    Dict.get (ServerID.toValue gatewayId) model.gateways
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


updateGateway : ServerID -> (Gateway -> Gateway) -> Model -> Model
updateGateway gatewayId updater model =
    let
        newGateways =
            Dict.update
                (ServerID.toValue gatewayId)
                (Maybe.map (\gtw -> updater gtw))
                model.gateways
    in
    { model | gateways = newGateways }


updateActiveGateway : (Gateway -> Gateway) -> Model -> Model
updateActiveGateway updater model =
    updateGateway model.activeGateway updater model


switchActiveGateway : ServerID -> Model -> Model
switchActiveGateway newActiveGatewayId model =
    { model | activeGateway = newActiveGatewayId }


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
        |> switchActiveGateway gateway.id
        |> updateActiveGateway (\gtw -> Server.switchActiveEndpoint gtw newActiveEndpointNip)



-- Model > Gateways


{-| Returns the gateway with the corresponding NIP. This function assumes that the NIP will always
exist. If there is a possibility it won't, use the `maybeFindGatewayByNip` variant.
-}
findGatewayByNip : Model -> NIP -> Gateway
findGatewayByNip model nip =
    Dict.find (\_ gtw -> gtw.nip == nip) model.gateways
        |> Maybe.map Tuple.second
        |> Maybe.withDefault Server.invalidGateway



-- Model > Tunnels


getAllTunnels : Model -> Tunnels
getAllTunnels model =
    getGateways model
        |> List.concatMap (\{ tunnels } -> tunnels)



-- Event handlers


onTunnelCreatedEvent : Model -> Events.TunnelCreated -> Model
onTunnelCreatedEvent model _ =
    model



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
