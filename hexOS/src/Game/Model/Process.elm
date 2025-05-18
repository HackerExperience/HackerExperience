module Game.Model.Process exposing
    ( Operation(..)
    , OperationStarted(..)
    , OperationStarting(..)
    )

import Game.Model.LogID exposing (LogID)
import Game.Model.ProcessID exposing (ProcessID)


type OperationStarting
    = LogDeleteStarting LogID


type OperationStarted
    = LogDeleteStarted LogID ProcessID


{-| NOTE: If this causes module conflicts, we can extract it to a ProcessOperation module
-}
type Operation
    = Starting OperationStarting
    | Started OperationStarted



-- | Completed
-- | StartFailed
