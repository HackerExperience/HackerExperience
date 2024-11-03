module Boot exposing (Model, Msg(..), documentView, init, update)

import Effect exposing (Effect)
import Event exposing (Event)
import Game.Model as Game
import UI exposing (UI, cl, col, row, text)



-- Types


type Msg
    = ProceedToGame Game.Model
    | EstablishSSEConnection
    | OnEventReceived Event


type alias Model =
    { token : String }



-- Model


init : String -> ( Model, Effect Msg )
init token =
    ( { token = token }
    , Effect.msgToCmd EstablishSSEConnection
    )



-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        -- Intercepted by `Main`
        ProceedToGame _ ->
            ( model, Effect.none )

        EstablishSSEConnection ->
            ( model, Effect.sseStart model.token )

        OnEventReceived event ->
            updateEvent model event


updateEvent : Model -> Event -> ( Model, Effect Msg )
updateEvent model event =
    case event of
        Event.IndexRequested index ->
            let
                spModel =
                    Game.init index
            in
            ( model, Effect.msgToCmd <| ProceedToGame spModel )



-- View


documentView : Model -> UI.Document Msg
documentView model =
    { title = "Hacker Experience", body = view model }


view : Model -> List (UI Msg)
view _ =
    [ col [ cl "p-boot-root" ]
        [ row [] [ text "Booting" ] ]
    ]
