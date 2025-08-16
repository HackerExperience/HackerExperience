module Game.Model.File exposing
    ( File
    , Files
    , filesToList
    , onAppStoreInstalledEvent
    , parse
    )

import API.Events.Types as Events
import Dict exposing (Dict)
import Game.Model.FileID as FileID exposing (FileID, RawFileID)
import Game.Model.InstallationID as InstallationID exposing (InstallationID, RawInstallationID)
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
    , installationId : Maybe InstallationID
    }



-- Model


filesToList : Files -> List File
filesToList files =
    Dict.toList files
        |> List.map (\( _, file ) -> file)



-- Model > Parser


parse : List Events.IdxFile -> Files
parse idxFiles =
    List.map (\idxFile -> ( idxFile.id, parseFile idxFile )) idxFiles
        |> Dict.fromList


parseFile : Events.IdxFile -> File
parseFile idxFile =
    let
        installationId =
            case idxFile.installation_id of
                OpenApi.Present rawInstallationId ->
                    Just <| InstallationID.fromValue rawInstallationId

                OpenApi.Null ->
                    Nothing
    in
    { id = FileID.fromValue idxFile.id
    , name = idxFile.name
    , path = idxFile.path
    , size = idxFile.size
    , type_ = SoftwareType.typeFromString idxFile.type_
    , version = idxFile.version
    , installationId = installationId
    }



-- Event handlers


onAppStoreInstalledEvent : Events.IdxFile -> Files -> Files
onAppStoreInstalledEvent idxFile files =
    Dict.insert idxFile.id (parseFile idxFile) files
