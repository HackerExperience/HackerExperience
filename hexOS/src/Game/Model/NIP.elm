module Game.Model.NIP exposing
    ( NIP
    , fromString
    , invalidNip
    , new
    , toString
    )


type alias NetworkID =
    String


type alias IP =
    String


type NIP
    = NIP NetworkID IP


new : String -> String -> NIP
new networkId ip =
    NIP networkId ip


fromString : String -> NIP
fromString rawNip =
    case String.split "@" rawNip of
        [ rawNetworkId, rawIp ] ->
            new rawNetworkId rawIp

        _ ->
            invalidNip


toString : NIP -> String
toString (NIP networkId ip) =
    networkId ++ "@" ++ ip


invalidNip : NIP
invalidNip =
    new "0" "0.0.0.0"
