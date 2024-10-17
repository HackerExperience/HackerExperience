module TestHelpers.Support.RandomUtils exposing (..)

import Random as R exposing (Generator)


oneOf2 : a -> a -> Generator a
oneOf2 a b =
    R.map
        (\idx ->
            case idx of
                1 ->
                    a

                _ ->
                    b
        )
        (R.int 0 1)
