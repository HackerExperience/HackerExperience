module Boot exposing (..)

import Event exposing (Event)
import UI exposing (UI, cl, col, id, row, style, text)
import Utils



-- Types


type Msg
    = ProceedToGame
    | EstablishSSEConnection
    | OnEventReceived Event
    | NoOp


type alias Model =
    { token : String }



-- Model


init : String -> ( Model, Cmd Msg )
init token =
    ( { token = token }
    , Utils.msgToCmd EstablishSSEConnection
    )



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Intercepted by `Main`
        ProceedToGame ->
            ( model, Cmd.none )

        -- Intercepted by `Main`
        EstablishSSEConnection ->
            ( model, Cmd.none )

        OnEventReceived event ->
            updateEvent model event

        NoOp ->
            ( model, Cmd.none )


updateEvent : Model -> Event -> ( Model, Cmd Msg )
updateEvent model event =
    case event of
        Event.IndexRequested { player } ->
            let
                _ =
                    Debug.log "mainframe id" player.mainframe
            in
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
