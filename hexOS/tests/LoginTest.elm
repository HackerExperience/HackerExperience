module LoginTest exposing (..)

import Effect
import Expect as E exposing (Expectation)
import Program exposing (program)
import ProgramTest as PT
import TestHelpers.Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Login"
        [ test "submits http request" testSubmitHttpRequest
        ]


testSubmitHttpRequest : () -> Expectation
testSubmitHttpRequest _ =
    program
        |> PT.clickButton "Login"
        |> PT.expectHttpRequestWasMade "POST" "http://localhost:4000/v1/user/login"
