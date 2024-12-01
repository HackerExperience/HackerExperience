module Boot exposing (Model, Msg(..), documentView, init, update)

import API.Types
import API.Utils
import Effect exposing (Effect)
import Event exposing (Event)
import Game.Model
import Game.Universe exposing (Universe(..))
import UI exposing (UI, cl, col, row, text)



-- Types


type Msg
    = ProceedToGame Game.Model.Model
    | EstablishSSEConnection
    | OnEventReceived Event


type alias Model =
    { token : API.Types.InputToken }



-- Model


init : API.Types.InputToken -> ( Model, Effect Msg )
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
            ( model, Effect.sseStart (API.Utils.tokenToString model.token) )

        OnEventReceived event ->
            updateEvent model event


updateEvent : Model -> Event -> ( Model, Effect Msg )
updateEvent model event =
    case event of
        Event.IndexRequested index ->
            let
                -- TODO: Create SP and MP model; currently hard-coding SP
                spModel =
                    Game.Model.init model.token Singleplayer index
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
