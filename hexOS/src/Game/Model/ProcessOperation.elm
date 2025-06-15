module Game.Model.ProcessOperation exposing
    ( Operation(..)
    , OperationType(..)
    )

import Game.Model.LogID exposing (LogID)
import Game.Model.ProcessID exposing (ProcessID)


{-| NOTE: Could this ever be replaced by ProcessType???
-}
type OperationType
    = LogDelete LogID
    | LogEdit LogID


type Operation
    = Starting OperationType
    | Started OperationType ProcessID
    | Finished OperationType ProcessID
    | StartFailed OperationType
