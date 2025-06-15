module Game.Model.ProcessData exposing
    ( ProcessData(..)
    , parse
    )

import API.Processes.Json as ProcessJD
import API.Processes.Types as ProcessJD
import Game.Model.LogID exposing (LogID)
import Json.Decode as JD


type ProcessData
    = FileDelete FileDeleteData
    | FileInstall FileInstallData
    | FileTransfer FileTransferData
    | InstallationUninstall InstallationUninstallData
    | LogDelete LogDeleteData
    | LogEdit LogEditData
    | InvalidProcess String


type alias FileDeleteData =
    {}


type alias FileInstallData =
    {}


type alias FileTransferData =
    {}


type alias InstallationUninstallData =
    {}


type alias LogEditData =
    { logId : LogID }


type alias LogDeleteData =
    { logId : LogID }


parse : { p | type_ : String, data : String } -> ProcessData
parse idxProcess =
    case idxProcess.type_ of
        "file_delete" ->
            parseData idxProcess ProcessJD.decodeFileDelete fileDeleteBuilder

        "file_install" ->
            parseData idxProcess ProcessJD.decodeFileInstall fileInstallBuilder

        "file_transfer" ->
            parseData idxProcess ProcessJD.decodeFileTransfer fileTransferBuilder

        "installation_uninstall" ->
            parseData idxProcess ProcessJD.decodeInstallationUninstall installationUninstallBuilder

        "log_delete" ->
            parseData idxProcess ProcessJD.decodeLogDelete logDeleteBuilder

        "log_edit" ->
            parseData idxProcess ProcessJD.decodeLogEdit logEditBuilder

        _ ->
            invalidData "unknown_type"


parseData :
    { p | type_ : String, data : String }
    -> JD.Decoder apiData
    -> (apiData -> ProcessData)
    -> ProcessData
parseData { data, type_ } decoder builder =
    let
        result =
            JD.decodeString decoder data
    in
    wrapResult result builder type_


wrapResult : Result x a -> (a -> ProcessData) -> String -> ProcessData
wrapResult result builder dataType =
    case result of
        Ok foo ->
            builder foo

        Err _ ->
            invalidData dataType


invalidData : String -> ProcessData
invalidData type_ =
    InvalidProcess type_



-- Data builders


fileDeleteBuilder : ProcessJD.FileDelete -> ProcessData
fileDeleteBuilder _ =
    FileDelete {}


fileInstallBuilder : ProcessJD.FileInstall -> ProcessData
fileInstallBuilder _ =
    FileInstall {}


fileTransferBuilder : ProcessJD.FileTransfer -> ProcessData
fileTransferBuilder _ =
    FileTransfer {}


installationUninstallBuilder : ProcessJD.InstallationUninstall -> ProcessData
installationUninstallBuilder _ =
    InstallationUninstall {}


logDeleteBuilder : ProcessJD.LogDelete -> ProcessData
logDeleteBuilder { log_id } =
    LogDelete { logId = log_id }


logEditBuilder : ProcessJD.LogEdit -> ProcessData
logEditBuilder { log_id } =
    LogEdit { logId = log_id }
