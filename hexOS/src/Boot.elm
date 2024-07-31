module Boot exposing (..)

import UI exposing (UI, cl, col, id, row, style, text)



-- Types


type Msg
    = ProceedToGame
    | NoOp


type alias Model =
    { token : String }



-- Model


initialModel : String -> Model
initialModel token =
    { token = token }



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ProceedToGame ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- View


documentView : Model -> UI.Document Msg
documentView model =
    { title = "Hacker Experience", body = view model }


view : Model -> List (UI Msg)
view model =
    [ col [ cl "p-boot-root" ]
        [ row [] [ text "Booting" ] ]
    ]
