-- This is an auto-generated file; manual changes will be overwritten!


module API.Events.Types exposing (IdxGateway, IdxLog, IdxPlayer, IdxTunnel, IndexRequested, TunnelCreated)

import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ServerID as ServerID exposing (ServerID(..))
import Game.Model.TunnelID as TunnelID exposing (TunnelID(..))


{-|


## Aliases

@docs IdxGateway, IdxLog, IdxPlayer, IdxTunnel, IndexRequested, TunnelCreated

-}
type alias TunnelCreated =
    { access : String
    , source_nip : NIP
    , target_nip : NIP
    , tunnel_id : TunnelID
    }


type alias IndexRequested =
    { player : IdxPlayer }


type alias IdxTunnel =
    { source_nip : NIP, target_nip : NIP, tunnel_id : TunnelID }


type alias IdxPlayer =
    { gateways : List IdxGateway, mainframe_id : ServerID }


type alias IdxLog =
    { id : Int, revision_id : Int, type_ : String }


type alias IdxGateway =
    { id : Int, logs : List IdxLog, nip : NIP, tunnels : List IdxTunnel }
