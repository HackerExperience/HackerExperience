module Game.Model.InstallationID exposing
    ( InstallationID(..)
    , RawInstallationID
    , fromValue
    )

-- Types


type InstallationID
    = InstallationID String


type alias RawInstallationID =
    String



-- Functions


fromValue : String -> InstallationID
fromValue id =
    InstallationID id
