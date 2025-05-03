module Game.Model.ProcessID exposing
    ( ProcessID(..)
    , toValue
    )

-- Types


type ProcessID
    = ProcessID String



-- Functions


toValue : ProcessID -> String
toValue (ProcessID id) =
    id
