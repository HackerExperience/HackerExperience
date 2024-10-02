module Program exposing (..)

import Effect exposing (Effect)
import Main
import ProgramTest exposing (..)
import Simulator


defaultFlags : Main.Flags
defaultFlags =
    { creds = ""
    , randomSeed1 = 1
    , randomSeed2 = 2
    , randomSeed3 = 3
    , randomSeed4 = 4
    , viewportX = 200
    , viewportY = 359
    }


program : ProgramTest (Main.Model ()) Main.Msg (Effect Main.Msg)
program =
    ProgramTest.createApplication
        { init = Main.init
        , update = Main.update
        , view = Main.view
        , onUrlRequest = Main.ClickedLink
        , onUrlChange = Main.ChangedUrl
        }
        |> ProgramTest.withBaseUrl "https://localhost:8080"
        |> ProgramTest.withSimulatedEffects Simulator.simulateEffect
        |> ProgramTest.start defaultFlags
