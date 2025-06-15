module Game.Model.ProcessOperation exposing
    ( Operation(..)
    , OperationType(..)
    )

import Game.Model.LogID exposing (LogID)
import Game.Model.ProcessID exposing (ProcessID)


{-| TODO: Could this ever be replaced by ProcessType???
-}
type OperationType
    = LogDelete LogID
    | LogEdit LogID



-- TODO: I may be able to simplify by doing: Started OperationStarting ProcessID


{-| NOTE: If this causes module conflicts, we can extract it to a ProcessOperation module
-}
type Operation
    = Starting OperationType
    | Started OperationType ProcessID
    | Finished OperationType ProcessID
    | StartFailed OperationType
