module Game.Model.LogID exposing
    ( LogID
    , fromValue
    , toValue
    )

-- Types


type LogID
    = LogID Int



-- Functions


toValue : LogID -> Int
toValue (LogID id) =
    id


fromValue : Int -> LogID
fromValue id =
    LogID id
