module Boot exposing (Model, Msg(..), documentView, init, update)

import API.Events.Types as Events
import API.Types
import Effect exposing (Effect)
import Event exposing (Event)
import Game
import Game.Universe exposing (Universe(..))
import UI exposing (UI, cl, col, row, text)



-- Types


type Msg
    = ProceedToGame Game.Model Game.Model
    | EstablishSSEConnections
    | OnEventReceived Event


type alias Model =
    { token : API.Types.InputToken
    , spIndex : Maybe Events.IndexRequested
    , mpIndex : Maybe Events.IndexRequested
    }



-- Model


init : API.Types.InputToken -> ( Model, Effect Msg )
init token =
    ( { token = token
      , spIndex = Nothing
      , mpIndex = Nothing
      }
    , Effect.msgToCmd EstablishSSEConnections
    )



-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        -- Intercepted by `Main`
        ProceedToGame _ _ ->
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
        Event.IndexRequested index universe ->
            let
                newModel =
                    case universe of
                        Singleplayer ->
                            { model | spIndex = Just index }

                        Multiplayer ->
                            { model | mpIndex = Just index }
            in
            case ( newModel.spIndex, newModel.mpIndex ) of
                ( Just spIndex, Just mpIndex ) ->
                    let
                        spModel =
                            Game.init model.token Singleplayer spIndex

                        mpModel =
                            Game.init model.token Multiplayer mpIndex
                    in
                    ( newModel, Effect.msgToCmd <| ProceedToGame spModel mpModel )

                _ ->
                    ( newModel, Effect.none )

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
