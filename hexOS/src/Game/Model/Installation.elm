module Game.Model.Installation exposing
    ( Installation
    , Installations
    , onAppStoreInstalledEvent
    , parse
    )

import API.Events.Types as Events
import Dict exposing (Dict)
import Game.Model.FileID as FileID exposing (FileID)
import Game.Model.InstallationID as InstallationID exposing (InstallationID, RawInstallationID)
import Game.Model.SoftwareType as SoftwareType exposing (SoftwareType)
import OpenApi.Common as OpenApi



-- Types


type alias Installations =
    Dict RawInstallationID Installation


type alias Installation =
    { id : InstallationID
    , fileId : Maybe FileID
    , fileType : SoftwareType
    , fileVersion : Int
    , memoryUsage : Int
    }



-- Model
-- Model > Parser


parse : List Events.IdxInstallation -> Installations
parse idxInstallations =
    List.map (\idxInstall -> ( idxInstall.id, parseInstallation idxInstall )) idxInstallations
        |> Dict.fromList


parseInstallation : Events.IdxInstallation -> Installation
parseInstallation idxInstallation =
    let
        fileId =
            case idxInstallation.file_id of
                OpenApi.Present v ->
                    Just (FileID.fromValue v)

                OpenApi.Null ->
                    Nothing
    in
    { id = InstallationID.fromValue idxInstallation.id
    , fileId = fileId
    , fileType = SoftwareType.typeFromString idxInstallation.file_type
    , fileVersion = idxInstallation.file_version
    , memoryUsage = idxInstallation.memory_usage
    }



-- Event handlers


onAppStoreInstalledEvent : Events.IdxInstallation -> Installations -> Installations
onAppStoreInstalledEvent idxInstallation installations =
    Dict.insert idxInstallation.id (parseInstallation idxInstallation) installations
