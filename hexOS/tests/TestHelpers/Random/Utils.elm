module TestHelpers.Random.Utils exposing (..)

import Random as R exposing (Generator)
import Random.Char
import Random.String exposing (string)


randomStr : Int -> Generator String
randomStr size =
    string size Random.Char.english


randomId : Generator String
randomId =
    string 16 Random.Char.english
