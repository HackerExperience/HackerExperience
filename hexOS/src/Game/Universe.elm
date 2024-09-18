module Game.Universe exposing (..)

-- Types


type alias Model =
    { mainframeID : Int }



-- Model


{-| TODO: The input here is probably the PlayerIndex ev payload
-}
init : Int -> Model
init mainframeID =
    { mainframeID = mainframeID }
