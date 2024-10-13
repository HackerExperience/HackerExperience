module TestHelpers.Mocks.Events exposing (..)

import API.Events.Types as Events


indexRequested : Events.IndexRequested
indexRequested =
    { player = { mainframe_id = 1 } }
