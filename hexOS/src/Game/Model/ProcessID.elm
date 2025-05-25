module Game.Model.ProcessID exposing
    ( ProcessID(..)
    , RawProcessID
    , fromValue
    , toValue
    )

-- Types


type ProcessID
    = ProcessID String


type alias RawProcessID =
    String



-- Functions


toValue : ProcessID -> String
toValue (ProcessID id) =
    id


fromValue : String -> ProcessID
fromValue id =
    ProcessID id
