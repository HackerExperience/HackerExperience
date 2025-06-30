module Game.Model.FileID exposing
    ( FileID(..)
    , RawFileID
    , fromValue
    )

-- Types


type FileID
    = FileID String


type alias RawFileID =
    String



-- Functions


fromValue : String -> FileID
fromValue id =
    FileID id
