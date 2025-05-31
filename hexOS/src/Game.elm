module Game exposing
    ( Model
    , buildApiContext
    , findEndpointServer
    , findGatewayServer
    , getActiveEndpointNip
    , getActiveGateway
    , getGateway
    , getGateways
    , getServer
    , handleProcessOperation
    , init
    , onLogDeletedEvent
    , onProcessCompletedEvent
    , onProcessCreatedEvent
    , onTunnelCreatedEvent
    , switchActiveEndpoint
    , switchActiveGateway
    )

import API.Events.Types as Events
import API.Types
import API.Utils
import Dict exposing (Dict)
import Game.Bus as Action exposing (Action)
import Game.Model.NIP as NIP exposing (NIP, RawNIP)
import Game.Model.ProcessOperation as Operation exposing (Operation)
import Game.Model.Server as Server exposing (Endpoint, Gateway, Server, ServerType(..))
import Game.Model.Tunnel as Tunnel exposing (Tunnels)
import Game.Universe exposing (Universe(..))
import Maybe.Extra as Maybe


type alias Model =
    { universe : Universe
    , mainframeNip : NIP
    , activeGateway : NIP
    , gateways : Dict RawNIP Gateway
    , endpoints : Dict RawNIP Endpoint
    , servers : Dict RawNIP Server
    , apiCtx : API.Types.InputContext
    }



-- Model


init : API.Types.InputToken -> Universe -> Events.IndexRequested -> Model
init token universe index =
    let
        gateways =
            Server.parseGateways index.player.gateways
    in
    { universe = universe
    , mainframeNip = index.player.mainframe_nip
    , activeGateway = index.player.mainframe_nip
    , gateways = gateways
    , endpoints = Server.parseEndpoints index.player.endpoints
    , servers = Server.parseServers gateways index.player.gateways index.player.endpoints
    , apiCtx = buildApiContext token universe
    }



-- Model > Server


{-| Returns the Server, assuming it must exist.
-}
getServer : Model -> NIP -> Server
getServer model nip =
    findServer model nip
        |> Maybe.withDefault Server.invalidServer


{-| Returns the Server, if it exists.
-}
findServer : Model -> NIP -> Maybe Server
findServer model nip =
    Dict.get (NIP.toString nip) model.servers


{-| Returns the Server, if it exists and if it's a Gateway.
-}
findGatewayServer : Model -> NIP -> Maybe Server
findGatewayServer model nip =
    findServer model nip
        |> Maybe.filter (\server -> server.type_ == ServerGateway)


{-| Returns the Server, if it exists and if it's a Endpoint.
-}
findEndpointServer : Model -> NIP -> Maybe Server
findEndpointServer model nip =
    findServer model nip
        |> Maybe.filter (\server -> server.type_ == ServerEndpoint)


{-| Updates the Server, if it exists. Perform a no-op if it doesn't.
-}
updateServer : NIP -> (Server -> Server) -> Model -> Model
updateServer nip updater model =
    let
        newServers =
            Dict.update
                (NIP.toString nip)
                (Maybe.map (\server -> updater server))
                model.servers
    in
    { model | servers = newServers }


updateServerWithAction : NIP -> (Server -> ( Server, Action )) -> Model -> ( Model, Action )
updateServerWithAction nip updater model =
    case findServer model nip of
        Just server ->
            doUpdateServerWithAction nip updater server model

        Nothing ->
            ( model, Action.ActionNoOp )


doUpdateServerWithAction :
    NIP
    -> (Server -> ( Server, Action ))
    -> Server
    -> Model
    -> ( Model, Action )
doUpdateServerWithAction nip updater server model =
    let
        ( newServer, action ) =
            updater server

        newServers =
            Dict.update
                (NIP.toString nip)
                (Maybe.map (\_ -> newServer))
                model.servers
    in
    ( { model | servers = newServers }, action )



-- Model > Gateway


getGateway : Model -> NIP -> Gateway
getGateway model nip =
    findGateway model nip
        |> Maybe.withDefault Server.invalidGateway


findGateway : Model -> NIP -> Maybe Gateway
findGateway model nip =
    Dict.get (NIP.toString nip) model.gateways


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
            Tunnel.findTunnelByTargetNip tunnels newActiveEndpointNip

        gateway =
            case tunnel of
                Just { sourceNip } ->
                    getGateway model sourceNip

                Nothing ->
                    Server.invalidGateway
    in
    model
        |> switchActiveGateway gateway.nip
        |> updateActiveGateway (\gtw -> Server.switchActiveEndpoint gtw newActiveEndpointNip)



-- Model > Processes


handleProcessOperation : Model -> NIP -> Operation -> Model
handleProcessOperation model nip operation =
    case operation of
        Operation.Starting _ ->
            defaultProcessStartingHandler model nip operation

        Operation.Started _ _ ->
            defaultProcessStartedHandler model nip operation

        Operation.Finished _ _ ->
            defaultProcessStartedHandler model nip operation


defaultProcessStartingHandler : Model -> NIP -> Operation -> Model
defaultProcessStartingHandler model nip operation =
    updateServer nip (Server.handleProcessOperation operation) model


defaultProcessStartedHandler : Model -> NIP -> Operation -> Model
defaultProcessStartedHandler model nip operation =
    updateServer nip (Server.handleProcessOperation operation) model



-- Model > Tunnels


getAllTunnels : Model -> Tunnels
getAllTunnels model =
    getGateways model
        |> List.concatMap (\{ tunnels } -> tunnels)



-- Event handlers


onLogDeletedEvent : Model -> Events.LogDeleted -> Model
onLogDeletedEvent model event =
    updateServer event.nip (Server.onLogDeletedEvent event) model


onProcessCompletedEvent : Model -> Events.ProcessCompleted -> ( Model, Action )
onProcessCompletedEvent model event =
    updateServerWithAction event.nip (Server.onProcessCompletedEvent event) model


onProcessCreatedEvent : Model -> Events.ProcessCreated -> ( Model, Action )
onProcessCreatedEvent model event =
    updateServerWithAction event.nip (Server.onProcessCreatedEvent event) model


onTunnelCreatedEvent : Model -> Events.TunnelCreated -> Model
onTunnelCreatedEvent model event =
    let
        gateway =
            findGateway model event.source_nip

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
