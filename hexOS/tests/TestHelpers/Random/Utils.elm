module TestHelpers.Random.Utils exposing (..)

import Game.Model.NIP as NIP exposing (NIP)
import Random as R exposing (Generator, int, map, map4)
import Random.Char
import Random.String exposing (string)


randomStr : Int -> Generator String
randomStr size =
    string size Random.Char.english


randomId : Generator String
randomId =
    string 16 Random.Char.english


randomNip : Generator NIP
randomNip =
    map (\rawIp -> NIP.fromString <| "0@" ++ rawIp)
        randomIpString


randomIpString : Generator String
randomIpString =
    map4
        (\o1 o2 o3 o4 ->
            let
                o1Str =
                    String.fromInt o1

                o2Str =
                    String.fromInt o2

                o3Str =
                    String.fromInt o3

                o4Str =
                    String.fromInt o4
            in
            o1Str ++ "." ++ o2Str ++ "." ++ o3Str ++ "." ++ o4Str
        )
        nipOctet
        nipOctet
        nipOctet
        nipOctet


nipOctet : Generator Int
nipOctet =
    int 0 255
