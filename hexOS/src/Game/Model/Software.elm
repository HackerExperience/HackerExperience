module Game.Model.Software exposing
    ( Manifest
    , Software
    , listAppStoreSoftware
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



-- Model


listAppStoreSoftware : Manifest -> List Software
listAppStoreSoftware manifest =
    let
        folderFn =
            \_ software acc ->
                case software.appStoreConfig of
                    Just _ ->
                        software :: acc

                    Nothing ->
                        acc
    in
    Dict.foldl folderFn [] manifest



-- Model > Parser


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
            , appStoreConfig = parseAppStoreConfig idxSoftware.config.appstore
            }
    in
    ( idxSoftware.type_, s )


parseAppStoreConfig : Maybe Events.SoftwareConfigAppstore -> Maybe AppStoreConfig
parseAppStoreConfig idxAppStoreConfig =
    Maybe.map (\{ price } -> { price = price, version = 10 }) idxAppStoreConfig
