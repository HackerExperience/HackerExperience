module Game.Model.File exposing
    ( File
    , Files
    , onAppStoreInstalledEvent
    , parse
    )

import API.Events.Types as Events
import Dict exposing (Dict)
import Game.Model.FileID as FileID exposing (FileID, RawFileID)
import Game.Model.SoftwareType as SoftwareType exposing (SoftwareType)
import OpenApi.Common as OpenApi



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



-- Event handlers


onAppStoreInstalledEvent : Events.AppstoreInstalled -> Files -> Files
onAppStoreInstalledEvent event files =
    -- The `file` object is optional in the `AppStoreInstalledEvent`. When absent, it means the File
    -- already exists (and only the Installation was missing). When present, it means the File was
    -- actually inserted by the AppStoreInstall process.
    case event.file of
        OpenApi.Present idxFile ->
            Dict.insert idxFile.id (parseFile idxFile) files

        OpenApi.Null ->
            files
