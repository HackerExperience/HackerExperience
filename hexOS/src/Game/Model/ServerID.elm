module Game.Model.ServerID exposing
    ( ServerID(..)
    , fromValue
    )

-- Types


type ServerID
    = ServerID String



-- Functions


fromValue : String -> ServerID
fromValue id =
    ServerID id
