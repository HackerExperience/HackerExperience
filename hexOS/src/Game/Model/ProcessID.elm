module Game.Model.ProcessID exposing
    ( ProcessID(..)
    , RawProcessID
    , fromValue
    , toString
    , toValue
    )

-- Types


type ProcessID
    = ProcessID String


type alias RawProcessID =
    String



-- Functions


toString : ProcessID -> String
toString logId =
    toValue logId


toValue : ProcessID -> String
toValue (ProcessID id) =
    id


fromValue : String -> ProcessID
fromValue id =
    ProcessID id
