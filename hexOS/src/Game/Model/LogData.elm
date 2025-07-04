module Game.Model.LogData exposing
    ( LogDataEmpty
    , LogDataNIP
    , LogDataText
    , parseLogDataNip
    , parseLogDataText
    )

import API.Logs.Json as LogsJD
import API.Logs.Types as LogsJD
import Game.Model.NIP as NIP exposing (NIP)
import Json.Decode as JD


type alias LogDataEmpty =
    {}


type alias LogDataText =
    { text : String }


type alias LogDataNIP =
    { nip : NIP }



-- type alias LogDataNIPProxy =
--     { fromNip : NIP
--     , toNip : NIP
--     }
-- type alias LogDataLocalFile =
--     { fileName : String
--     , fileExt : String
--     , fileVersion : Int
--     }
-- type alias LogDataRemoteFile =
--     { nip : NIP
--     , fileName : String
--     , fileExt : String
--     , fileVersion : Int
--     }
-- Parsers


parseLogDataText : String -> LogDataText
parseLogDataText raw =
    let
        result =
            JD.decodeString LogsJD.decodeLogDataText raw
    in
    case result of
        Ok data ->
            mapLogDataText data

        Err _ ->
            invalidLogDataText


parseLogDataNip : String -> LogDataNIP
parseLogDataNip raw =
    let
        result =
            JD.decodeString LogsJD.decodeLogDataNIP raw
    in
    case result of
        Ok data ->
            mapLogDataNip data

        Err _ ->
            invalidLogDataNip



-- parseLogDataNipProxy : String -> LogDataNIPProxy
-- parseLogDataNipProxy raw =
--     let
--         result =
--             JD.decodeString LogsJD.decodeLogDataNIPProxy raw
--     in
--     case result of
--         Ok data ->
--             mapLogDataNipProxy data
--         Err error ->
--             invalidLogDataNipProxy
-- parseLogDataLocalFile : String -> LogDataLocalFile
-- parseLogDataLocalFile raw =
--     let
--         result =
--             JD.decodeString LogsJD.decodeLogDataLocalFile raw
--     in
--     case result of
--         Ok data ->
--             mapLogDataLocalFile data
--         Err error ->
--             invalidLogDataLocalFile
-- parseLogDataRemoteFile : String -> LogDataRemoteFile
-- parseLogDataRemoteFile raw =
--     let
--         result =
--             JD.decodeString LogsJD.decodeLogDataRemoteFile raw
--     in
--     case result of
--         Ok data ->
--             mapLogDataRemoteFile data
--         Err error ->
--             invalidLogDataRemoteFile
-- Mappers


mapLogDataText : LogsJD.LogDataText -> LogDataText
mapLogDataText data =
    data


mapLogDataNip : LogsJD.LogDataNIP -> LogDataNIP
mapLogDataNip data =
    data



-- mapLogDataNipProxy : LogsJD.LogDataNIPProxy -> LogDataNIPProxy
-- mapLogDataNipProxy data =
--     { fromNip = data.from_nip
--     , toNip = data.to_nip
--     }
-- mapLogDataLocalFile : LogsJD.LogDataLocalFile -> LogDataLocalFile
-- mapLogDataLocalFile data =
--     { fileName = data.file_name
--     , fileExt = data.file_ext
--     , fileVersion = data.file_version
--     }
-- mapLogDataRemoteFile : LogsJD.LogDataRemoteFile -> LogDataRemoteFile
-- mapLogDataRemoteFile data =
--     { nip = data.nip
--     , fileName = data.file_name
--     , fileExt = data.file_ext
--     , fileVersion = data.file_version
--     }
-- Misc


invalidLogDataText : LogDataText
invalidLogDataText =
    { text = "Invalid LogData text" }


invalidLogDataNip : LogDataNIP
invalidLogDataNip =
    { nip = NIP.invalidNip }



-- invalidLogDataNipProxy : LogDataNIPProxy
-- invalidLogDataNipProxy =
--     { fromNip = NIP.invalidNip, toNip = NIP.invalidNip }
-- invalidLogDataLocalFile : LogDataLocalFile
-- invalidLogDataLocalFile =
--     { fileName = "invalid"
--     , fileExt = "inv"
--     , fileVersion = 10
--     }
-- invalidLogDataRemoteFile : LogDataRemoteFile
-- invalidLogDataRemoteFile =
--     { nip = NIP.invalidNip
--     , fileName = "invalid"
--     , fileExt = "inv"
--     , fileVersion = 10
--     }
