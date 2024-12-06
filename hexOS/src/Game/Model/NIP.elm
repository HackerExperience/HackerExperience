module Game.Model.NIP exposing
    ( NIP
    , fromString
    , invalidNip
    , new
    , toString
    )


type NetworkID
    = NetworkID String


type IP
    = IP String


type NIP
    = NIP NetworkID IP


new : String -> String -> NIP
new rawNetworkId rawIp =
    NIP (NetworkID rawNetworkId) (IP rawIp)


fromString : String -> NIP
fromString rawNip =
    case String.split "@" rawNip of
        [ rawNetworkId, rawIp ] ->
            new rawNetworkId rawIp

        _ ->
            invalidNip


toString : NIP -> String
toString (NIP (NetworkID networkId) (IP ip)) =
    networkId ++ "@" ++ ip


invalidNip : NIP
invalidNip =
    new "0" "0.0.0.0"
