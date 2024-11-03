module Game.Model.LogID exposing
    ( LogID
    , RawLogID
    , fromValue
    , toValue
    )

-- Types


type LogID
    = LogID Int


type alias RawLogID =
    Int



-- Functions


toValue : LogID -> Int
toValue (LogID id) =
    id


fromValue : Int -> LogID
fromValue id =
    LogID id
