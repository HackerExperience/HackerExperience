module Game.Model.Tunnel exposing
    ( Tunnel
    , Tunnels
    )

-- import API.Events.Types as Events

import Game.Model.NIP exposing (NIP)
import Game.Model.TunnelID exposing (TunnelID)



-- Types


type alias Tunnel =
    { id : TunnelID
    , sourceNip : NIP
    , targetNip : NIP
    }


type alias Tunnels =
    List Tunnel



-- Model
-- fromTunnelCreatedEvent : Events.TunnelCreated -> Tunnel
-- fromTunnelCreatedEvent event =
--     { id = event.tunnel_id
--     , sourceNip = event.source_nip
--     , targetNip = event.target_nip
--     }
