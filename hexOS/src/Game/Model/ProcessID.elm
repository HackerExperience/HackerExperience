module Game.Model.ProcessID exposing
    ( ProcessID(..)
    , fromValue
    , toValue
    )

-- Types


type ProcessID
    = ProcessID String



-- Functions


toValue : ProcessID -> String
toValue (ProcessID id) =
    id


fromValue : String -> ProcessID
fromValue id =
    ProcessID id
