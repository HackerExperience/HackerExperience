module Game.Model.Software exposing
    ( Manifest
    , Software
    , getAppStoreInstallableSoftware
    , listAppStoreSoftware
    , parseManifest
    )

import API.Events.Types as Events
import Dict exposing (Dict)
import Game.Model.File exposing (Files)
import Game.Model.FileID exposing (FileID)
import Game.Model.Installation exposing (Installations)
import Game.Model.SoftwareType as SoftwareType exposing (SoftwareType)
import List.Extra as List
import Maybe.Extra as Maybe


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


{-| Returns a list of AppStore-installable software.

The software is installable if either:

  - There's no matching software as part of the Server's files; or
  - There's no matching software as part of the Server's installations.

"Matching software" here means a software of same type and version.

-}
getAppStoreInstallableSoftware : List Software -> Files -> Installations -> List SoftwareType
getAppStoreInstallableSoftware softwares files installations =
    let
        doesFileExist =
            \software version ->
                List.find
                    (\( _, file ) -> file.type_ == software.type_ && file.version == version)
                    (Dict.toList files)
                    |> Maybe.isJust

        doesInstallationExist =
            \software version ->
                List.find
                    (\( _, inst ) -> inst.fileType == software.type_ && inst.fileVersion == version)
                    (Dict.toList installations)
                    |> Maybe.isJust

        isSoftwareInstallable =
            -- If File and Installation exist for the exact version, it is not installable. It is
            -- installable in any other scenario.
            \software version ->
                not (doesFileExist software version && doesInstallationExist software version)

        builderFn =
            \software acc ->
                case software.appStoreConfig of
                    Just { version } ->
                        if isSoftwareInstallable software version then
                            software.type_ :: acc

                        else
                            acc

                    Nothing ->
                        acc
    in
    List.foldl builderFn [] softwares



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
