module Game.Model.ServerID exposing
    ( RawServerID
    , ServerID(..)
    , fromValue
    , toValue
    )

-- Types


type ServerID
    = ServerID String


type alias RawServerID =
    String



-- Functions


toValue : ServerID -> String
toValue (ServerID id) =
    id


fromValue : String -> ServerID
fromValue id =
    ServerID id
