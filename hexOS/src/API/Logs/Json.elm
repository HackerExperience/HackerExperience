-- This is an auto-generated file; manual changes will be overwritten!


module API.Logs.Json exposing
    ( encodeLogDataEmpty, encodeLogDataLocalFile, encodeLogDataNIP, encodeLogDataNIPProxy
    , encodeLogDataRemoteFile, encodeLogDataText
    , decodeLogDataEmpty, decodeLogDataLocalFile, decodeLogDataNIP, decodeLogDataNIPProxy
    , decodeLogDataRemoteFile, decodeLogDataText
    )

{-|


## Encoders

@docs encodeLogDataEmpty, encodeLogDataLocalFile, encodeLogDataNIP, encodeLogDataNIPProxy
@docs encodeLogDataRemoteFile, encodeLogDataText


## Decoders

@docs decodeLogDataEmpty, decodeLogDataLocalFile, decodeLogDataNIP, decodeLogDataNIPProxy
@docs decodeLogDataRemoteFile, decodeLogDataText

-}

import API.Logs.Types
import Game.Model.LogID as LogID exposing (LogID(..))
import Game.Model.NIP as NIP exposing (NIP(..))
import Game.Model.ProcessID as ProcessID exposing (ProcessID(..))
import Game.Model.ServerID as ServerID exposing (ServerID(..))
import Game.Model.TunnelID as TunnelID exposing (TunnelID(..))
import Json.Decode
import Json.Encode
import OpenApi.Common


decodeLogDataText : Json.Decode.Decoder API.Logs.Types.LogDataText
decodeLogDataText =
    Json.Decode.succeed
        (\text -> { text = text })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "text"
                Json.Decode.string
            )


encodeLogDataText : API.Logs.Types.LogDataText -> Json.Encode.Value
encodeLogDataText rec =
    Json.Encode.object [ ( "text", Json.Encode.string rec.text ) ]


decodeLogDataRemoteFile : Json.Decode.Decoder API.Logs.Types.LogDataRemoteFile
decodeLogDataRemoteFile =
    Json.Decode.succeed
        (\file_ext file_name file_version nip ->
            { file_ext = file_ext
            , file_name = file_name
            , file_version = file_version
            , nip = nip
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "file_ext" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "file_name"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "file_version"
                Json.Decode.int
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "nip"
                (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string)
            )


encodeLogDataRemoteFile : API.Logs.Types.LogDataRemoteFile -> Json.Encode.Value
encodeLogDataRemoteFile rec =
    Json.Encode.object
        [ ( "file_ext", Json.Encode.string rec.file_ext )
        , ( "file_name", Json.Encode.string rec.file_name )
        , ( "file_version", Json.Encode.int rec.file_version )
        , ( "nip", Json.Encode.string (NIP.toString rec.nip) )
        ]


decodeLogDataNIPProxy : Json.Decode.Decoder API.Logs.Types.LogDataNIPProxy
decodeLogDataNIPProxy =
    Json.Decode.succeed
        (\from_nip to_nip -> { from_nip = from_nip, to_nip = to_nip })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "from_nip" (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string))
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "to_nip" (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string))


encodeLogDataNIPProxy : API.Logs.Types.LogDataNIPProxy -> Json.Encode.Value
encodeLogDataNIPProxy rec =
    Json.Encode.object
        [ ( "from_nip", Json.Encode.string (NIP.toString rec.from_nip) )
        , ( "to_nip", Json.Encode.string (NIP.toString rec.to_nip) )
        ]


decodeLogDataNIP : Json.Decode.Decoder API.Logs.Types.LogDataNIP
decodeLogDataNIP =
    Json.Decode.succeed
        (\nip -> { nip = nip })
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "nip"
                (Json.Decode.map (\nip -> NIP.fromString nip) Json.Decode.string)
            )


encodeLogDataNIP : API.Logs.Types.LogDataNIP -> Json.Encode.Value
encodeLogDataNIP rec =
    Json.Encode.object [ ( "nip", Json.Encode.string (NIP.toString rec.nip) ) ]


decodeLogDataLocalFile : Json.Decode.Decoder API.Logs.Types.LogDataLocalFile
decodeLogDataLocalFile =
    Json.Decode.succeed
        (\file_ext file_name file_version ->
            { file_ext = file_ext
            , file_name = file_name
            , file_version = file_version
            }
        )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field "file_ext" Json.Decode.string)
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "file_name"
                Json.Decode.string
            )
        |> OpenApi.Common.jsonDecodeAndMap
            (Json.Decode.field
                "file_version"
                Json.Decode.int
            )


encodeLogDataLocalFile : API.Logs.Types.LogDataLocalFile -> Json.Encode.Value
encodeLogDataLocalFile rec =
    Json.Encode.object
        [ ( "file_ext", Json.Encode.string rec.file_ext )
        , ( "file_name", Json.Encode.string rec.file_name )
        , ( "file_version", Json.Encode.int rec.file_version )
        ]


decodeLogDataEmpty : Json.Decode.Decoder API.Logs.Types.LogDataEmpty
decodeLogDataEmpty =
    Json.Decode.succeed {}


encodeLogDataEmpty : API.Logs.Types.LogDataEmpty -> Json.Encode.Value
encodeLogDataEmpty rec =
    Json.Encode.object []
