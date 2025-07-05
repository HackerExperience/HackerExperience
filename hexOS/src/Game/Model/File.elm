module Game.Model.File exposing
    ( File
    , Files
    , parse
    )

import API.Events.Types as Events
import Dict exposing (Dict)
import Game.Model.FileID as FileID exposing (FileID, RawFileID)
import Game.Model.SoftwareType as SoftwareType exposing (SoftwareType)



-- Types


type alias Files =
    Dict RawFileID File


type alias File =
    { id : FileID
    , name : String
    , path : String
    , size : Int
    , type_ : SoftwareType
    , version : Int
    }



-- Model
-- Model > Parser


parse : List Events.IdxFile -> Files
parse idxFiles =
    List.map (\idxFile -> ( idxFile.id, parseFile idxFile )) idxFiles
        |> Dict.fromList


parseFile : Events.IdxFile -> File
parseFile idxFile =
    { id = FileID.fromValue idxFile.id
    , name = idxFile.name
    , path = idxFile.path
    , size = idxFile.size
    , type_ = SoftwareType.typeFromString idxFile.type_
    , version = idxFile.version
    }
