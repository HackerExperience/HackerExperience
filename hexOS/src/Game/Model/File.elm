module Game.Model.File exposing
    ( File
    , Files
    , filesToList
    , onAppStoreInstalledEvent
    , onFileDeletedEvent
    , onFileInstalledEvent
    , onInstallationUninstalledEvent
    , parse
    )

import API.Events.Types as Events
import Dict exposing (Dict)
import Dict.Extra as Dict
import Game.Model.FileID as FileID exposing (FileID, RawFileID)
import Game.Model.InstallationID as InstallationID exposing (InstallationID)
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
    Dict.values files


updateFile : FileID -> (File -> File) -> Files -> Files
updateFile fileId updater files =
    let
        updaterFn =
            \maybeFile ->
                case maybeFile of
                    Just file ->
                        Just <| updater file

                    Nothing ->
                        Nothing
    in
    Dict.update (FileID.toString fileId) updaterFn files



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


onFileDeletedEvent : Events.FileDeleted -> Files -> Files
onFileDeletedEvent event files =
    Dict.remove (FileID.toValue event.file_id) files


onFileInstalledEvent : Events.IdxFile -> Files -> Files
onFileInstalledEvent idxFile files =
    Dict.insert idxFile.id (parseFile idxFile) files


onInstallationUninstalledEvent : Events.InstallationUninstalled -> Files -> Files
onInstallationUninstalledEvent event files =
    -- The installation may belong to an existing file. Let's try to find it. If found, nullify it.
    let
        matchingFile =
            Dict.find (\_ { installationId } -> installationId == Just event.installation_id) files

        updater =
            \file -> { file | installationId = Nothing }
    in
    case matchingFile of
        Just ( fileId, _ ) ->
            updateFile (FileID.fromValue fileId) updater files

        Nothing ->
            files
