module Game.Model.Log exposing (Log)

import Game.Model.LogID exposing (LogID)



-- Types


type alias Log =
    { id : LogID
    , revisionId : Int
    , type_ : String
    }
