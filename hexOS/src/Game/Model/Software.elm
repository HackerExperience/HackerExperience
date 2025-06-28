module Game.Model.Software exposing
    ( Manifest
    , Software
    , parseManifest
    )

import API.Events.Types as Events
import Dict exposing (Dict)
import Game.Model.SoftwareType as SoftwareType exposing (SoftwareType)


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
            { type_ = SoftwareType.typeFromString idxSoftware.type_
            , extension = idxSoftware.extension
            , appStoreConfig = Nothing
            }
    in
    ( idxSoftware.type_, s )
