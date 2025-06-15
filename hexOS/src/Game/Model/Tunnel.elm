module Game.Model.Tunnel exposing
    ( Tunnel
    , Tunnels
    , findTunnelByTargetNip
    , fromTunnelCreatedEvent
    , parse
    )

import API.Events.Types as Events
import Game.Model.NIP exposing (NIP)
import Game.Model.TunnelID exposing (TunnelID)
import List.Extra as List



-- Types


type alias Tunnel =
    { id : TunnelID
    , sourceNip : NIP
    , targetNip : NIP
    }


type alias Tunnels =
    List Tunnel



-- Model


fromTunnelCreatedEvent : Events.TunnelCreated -> Tunnel
fromTunnelCreatedEvent event =
    { id = event.tunnel_id
    , sourceNip = event.source_nip
    , targetNip = event.target_nip
    }



-- Model > Index Parser


parse : List Events.IdxTunnel -> Tunnels
parse idxTunnels =
    List.map (\idxTunnel -> parseTunnel idxTunnel) idxTunnels


parseTunnel : Events.IdxTunnel -> Tunnel
parseTunnel idxTunnel =
    { id = idxTunnel.tunnel_id
    , sourceNip = idxTunnel.source_nip
    , targetNip = idxTunnel.target_nip
    }



-- Model > Query


findTunnelByTargetNip : Tunnels -> NIP -> Maybe Tunnel
findTunnelByTargetNip tunnels targetNip =
    List.find (\t -> t.targetNip == targetNip) tunnels
