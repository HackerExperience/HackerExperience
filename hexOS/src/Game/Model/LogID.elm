module Game.Model.LogID exposing
    ( LogID
    , RawLogID
    , fromValue
    , toValue
    )

-- Types


type LogID
    = LogID String


type alias RawLogID =
    String



-- Functions


toValue : LogID -> String
toValue (LogID id) =
    id


fromValue : String -> LogID
fromValue id =
    LogID id
