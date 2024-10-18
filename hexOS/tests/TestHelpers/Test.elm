module TestHelpers.Test exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer)
import Random exposing (Generator)
import Test


type alias Test =
    Test.Test


describe : String -> List Test -> Test
describe =
    Test.describe


test : String -> (() -> Expectation) -> Test
test =
    Test.test


{-| Use `fuzzOnce` when you want to fuzz (use random values) but it's meaningless for that
particular test to run dozens of times, even in CI.
-}
fuzzOnce : Fuzzer a -> String -> (a -> Expectation) -> Test
fuzzOnce =
    Test.fuzzWith { runs = 1, distribution = Test.noDistribution }


toFuzzer : Generator a -> Fuzzer a
toFuzzer generator =
    Fuzz.fromGenerator generator
