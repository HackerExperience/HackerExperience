module Game.Model.Software exposing (..)

import API.Events.Types as Events
import API.Types
import Dict exposing (Dict)


type SoftwareType
    = SoftwareCracker
    | SoftwareLogEditor
    | SoftwareInvalid String


type alias Software =
    { type_ : SoftwareType
    , extension : String
    , appStoreConfig : Maybe AppStoreConfig
    }


type alias AppStoreConfig =
    { price : Int
    , version : Int
    }


type alias Manifest =
    Dict String Software


parseManifest : List Events.SoftwareManifest -> Manifest
parseManifest idxManifest =
    List.map parseManifestSoftware idxManifest
        |> Dict.fromList


parseManifestSoftware : Events.SoftwareManifest -> ( String, Software )
parseManifestSoftware idxSoftware =
    let
        s =
            { type_ = typeFromString idxSoftware.type_
            , extension = idxSoftware.extension
            , appStoreConfig = Nothing
            }
    in
    ( idxSoftware.type_, s )


typeToString : SoftwareType -> String
typeToString type_ =
    case type_ of
        SoftwareCracker ->
            "cracker"

        SoftwareLogEditor ->
            "log_editor"

        SoftwareInvalid str ->
            "invalid:" ++ str


typeFromString : String -> SoftwareType
typeFromString rawType =
    case rawType of
        "cracker" ->
            SoftwareCracker

        "log_editor" ->
            SoftwareLogEditor

        _ ->
            SoftwareInvalid rawType
