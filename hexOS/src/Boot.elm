module Boot exposing (Model, Msg(..), documentView, init, update)

import API.Types
import Effect exposing (Effect)
import Event exposing (Event)
import Game.Model
import Game.Universe exposing (Universe(..))
import UI exposing (UI, cl, col, row, text)



-- Types


type Msg
    = ProceedToGame Game.Model.Model
    | EstablishSSEConnections
    | OnEventReceived Event


type alias Model =
    { token : API.Types.InputToken }



-- Model


init : API.Types.InputToken -> ( Model, Effect Msg )
init token =
    ( { token = token }
    , Effect.msgToCmd EstablishSSEConnections
    )



-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        -- Intercepted by `Main`
        ProceedToGame _ ->
            ( model, Effect.none )

        EstablishSSEConnections ->
            let
                -- TODO: Build the urls based on the env
                spBaseUrl =
                    "http://localhost:4001"

                mpBaseUrl =
                    "http://localhost:4002"
            in
            ( model
            , Effect.batch
                [ Effect.sseStart model.token spBaseUrl
                , Effect.sseStart model.token mpBaseUrl
                ]
            )

        OnEventReceived event ->
            updateEvent model event


updateEvent : Model -> Event -> ( Model, Effect Msg )
updateEvent model event =
    case event of
        Event.IndexRequested index _ ->
            let
                -- TODO: Create SP and MP model; currently hard-coding SP
                spModel =
                    Game.Model.init model.token Singleplayer index
            in
            ( model, Effect.msgToCmd <| ProceedToGame spModel )

        _ ->
            ( model, Effect.none )



-- View


documentView : Model -> UI.Document Msg
documentView model =
    { title = "Hacker Experience", body = view model }


view : Model -> List (UI Msg)
view _ =
    [ col [ cl "p-boot-root" ]
        [ row [] [ text "Booting" ] ]
    ]
