module Game.Model.TunnelID exposing
    ( TunnelID(..)
    , toValue
    )

{-| TODO: Actual tunnel ID isn't `int`. Yet TBD.
-}

-- Types


type TunnelID
    = TunnelID Int



-- Functions


toValue : TunnelID -> Int
toValue (TunnelID id) =
    id
