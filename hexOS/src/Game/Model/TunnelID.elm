module Game.Model.TunnelID exposing
    ( RawTunnelID
    , TunnelID(..)
    , fromValue
    , toValue
    )

{-| TODO: Actual tunnel ID isn't `int`. Yet TBD.
-}

-- Types


type TunnelID
    = TunnelID Int


type alias RawTunnelID =
    Int



-- Functions


toValue : TunnelID -> Int
toValue (TunnelID id) =
    id


fromValue : Int -> TunnelID
fromValue id =
    TunnelID id
