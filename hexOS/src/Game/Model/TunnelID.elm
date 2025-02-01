module Game.Model.TunnelID exposing
    ( TunnelID(..)
    , toValue
    )

-- Types


type TunnelID
    = TunnelID String



-- Functions


toValue : TunnelID -> String
toValue (TunnelID id) =
    id
