module Game.Model.LogID exposing
    ( LogID(..)
    , RawLogID
    , fromValue
    , toString
    , toValue
    )

-- Types


type LogID
    = LogID String


type alias RawLogID =
    String



-- Functions


toString : LogID -> String
toString logId =
    toValue logId


toValue : LogID -> String
toValue (LogID id) =
    id


fromValue : String -> LogID
fromValue id =
    LogID id
