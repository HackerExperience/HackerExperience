module LoginTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Program exposing (program)
import ProgramTest exposing (clickButton, expectHttpRequestWasMade)
import Test exposing (..)
import Test.Html.Selector exposing (text)


suite : Test
suite =
    describe "Login"
        [ test "submits http request" <| testSubmitHttpRequest
        ]


testSubmitHttpRequest : () -> Expectation
testSubmitHttpRequest _ =
    program
        |> clickButton "Login"
        |> expectHttpRequestWasMade "POST" "http://localhost:4000/v1/user/login"
