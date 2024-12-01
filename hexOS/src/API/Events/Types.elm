module API.Events.Types exposing (IdxGateway, IdxLog, IdxPlayer, IndexRequested, TunnelCreated)

{-|


## Aliases

@docs IdxGateway, IdxLog, IdxPlayer, IndexRequested, TunnelCreated

-}


type alias TunnelCreated =
    { access : String
    , source_nip : String
    , target_nip : String
    , tunnel_id : String
    }


type alias IndexRequested =
    { player : IdxPlayer }


type alias IdxPlayer =
    { gateways : List IdxGateway, mainframe_id : Int }


type alias IdxLog =
    { id : Int, revision_id : Int, type_ : String }


type alias IdxGateway =
    { id : Int, logs : List IdxLog, nip : String }
