module Game.Model.ServerID exposing
    ( ServerID
    , fromValue
    , toValue
    )

{-| TODO: Actual server ID isn't `int`. Yet TBD.
-}

-- Types


type ServerID
    = ServerID Int



-- Functions


toValue : ServerID -> Int
toValue (ServerID id) =
    id


fromValue : Int -> ServerID
fromValue id =
    ServerID id
