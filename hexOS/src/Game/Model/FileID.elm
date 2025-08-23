module Game.Model.FileID exposing
    ( FileID(..)
    , RawFileID
    , fromValue
    , toString
    , toValue
    )

-- Types


type FileID
    = FileID String


type alias RawFileID =
    String



-- Functions


toString : FileID -> String
toString logId =
    toValue logId


toValue : FileID -> String
toValue (FileID id) =
    id


fromValue : String -> FileID
fromValue id =
    FileID id
