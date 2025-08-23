module Game.Model.InstallationID exposing
    ( InstallationID(..)
    , RawInstallationID
    , fromValue
    , toString
    , toValue
    )

-- Types


type InstallationID
    = InstallationID String


type alias RawInstallationID =
    String



-- Functions


toString : InstallationID -> String
toString installationId =
    toValue installationId


toValue : InstallationID -> String
toValue (InstallationID id) =
    id


fromValue : String -> InstallationID
fromValue id =
    InstallationID id
