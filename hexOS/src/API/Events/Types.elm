module API.Events.Types exposing (IdxPlayer, IndexRequested)

{-|


## Aliases

@docs IdxPlayer, IndexRequested

-}


type alias IndexRequested =
    { player : IdxPlayer }


type alias IdxPlayer =
    { mainframe_id : Int }
