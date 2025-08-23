module Game.Model.ServerID exposing
    ( ServerID(..)
    , fromValue
    , toString
    )

-- Types


type ServerID
    = ServerID String



-- Functions


toString : ServerID -> String
toString serverId =
    toValue serverId


toValue : ServerID -> String
toValue (ServerID id) =
    id


fromValue : String -> ServerID
fromValue id =
    ServerID id
