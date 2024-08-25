port module Main exposing (main)

import Boot
import Browser
import Browser.Events
import Browser.Navigation as Nav
import Core.Debounce as Debounce
import Debounce exposing (Debounce)
import Dict exposing (Dict)
import Event exposing (Event)
import Html exposing (Html)
import Json.Decode as JD
import Login
import OS
import Process
import Random
import Result
import Task
import UI exposing (UI)
import UUID exposing (Seeds, UUID)
import Url exposing (Url)
import Utils
import WM


type Msg
    = ClickedLink Browser.UrlRequest
    | ChangedUrl Url
      -- | BrowserResizedViewport ( Int, Int )
      -- | ResizedViewportDebounced ( Int, Int )
      -- | ResizedViewportDebouncing Debounce.Msg
    | BrowserMouseUp
    | BrowserVisibilityChanged Browser.Events.Visibility
    | OSMsg OS.Msg
    | LoginMsg Login.Msg
    | BootMsg Boot.Msg
    | OnRawEventReceived String
    | OnEventReceived (Result JD.Error Event)


type alias GameModel =
    { os : OS.Model }


type State
    = LoginState Login.Model
    | BootState Boot.Model
    | GameState GameModel
    | InstallState
    | ErrorState


type alias Model =
    { seeds : Seeds
    , state : State

    -- , resizeDebouncer : Debounce ( Int, Int )
    }


type alias Flags =
    { creds : String
    , randomSeed1 : Int
    , randomSeed2 : Int
    , randomSeed3 : Int
    , randomSeed4 : Int
    , viewportX : Int
    , viewportY : Int
    }



-- Port (TODO)


port eventStart : String -> Cmd msg


port eventSubscriber : (String -> msg) -> Sub msg



-- Main


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = ClickedLink
        , onUrlChange = ChangedUrl
        }



-- Model


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        -- route =
        --     Route.fromUrl url
        credentials =
            Just "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MDk3NTMxNDgsImFfaWQiOiJhZmY1YWIwYi1mZmRiLTQ2ODgtOWY0Zi0zMzExNjZjZDM2YTgiLCJjX2lkIjoiYWZmNWFiMGItZmZkYi00Njg4LTlmNGYtMzMxMTY2Y2QzNmE4IiwiaWF0IjoxNzA5MTQ4MzQ4fQ.lGPrwspZAkMRfA-xsvt0RNoesigGNh9qDbC3SpMbqWQ"

        -- ( osModel, osCmd ) =
        --     OS.init ( flags.viewportX, flags.viewportY )
        osCmd =
            Cmd.none

        firstSeeds =
            Seeds
                (Random.initialSeed flags.randomSeed1)
                (Random.initialSeed flags.randomSeed2)
                (Random.initialSeed flags.randomSeed3)
                (Random.initialSeed flags.randomSeed4)
    in
    ( { seeds = firstSeeds
      , state = LoginState Login.initialModel

      -- , resizeDebouncer = Debounce.init
      }
    , Cmd.batch
        [ Cmd.map OSMsg osCmd
        ]
    )



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.state of
        LoginState loginModel ->
            case msg of
                LoginMsg (Login.ProceedToBoot token) ->
                    let
                        ( bootModel, bootCmd ) =
                            Boot.init token
                    in
                    ( { model | state = BootState bootModel }, Cmd.map BootMsg bootCmd )

                LoginMsg subMsg ->
                    let
                        ( newLoginModel, loginCmd ) =
                            Login.update subMsg loginModel
                    in
                    ( { model | state = LoginState newLoginModel }
                    , Cmd.batch [ Cmd.map LoginMsg loginCmd ]
                    )

                _ ->
                    ( model, Cmd.none )

        BootState bootModel ->
            case msg of
                BootMsg Boot.ProceedToGame ->
                    -- ( { model | state = GameState (Boot.initialModel token) }, Cmd.none )
                    ( model, Cmd.none )

                BootMsg Boot.EstablishSSEConnection ->
                    ( model, eventStart bootModel.token )

                BootMsg subMsg ->
                    let
                        ( newBootModel, bootCmd ) =
                            Boot.update subMsg bootModel
                    in
                    ( { model | state = BootState newBootModel }
                    , Cmd.batch [ Cmd.map BootMsg bootCmd ]
                    )

                OnRawEventReceived rawEvent ->
                    let
                        eventResult =
                            Event.processReceivedEvent rawEvent

                        _ =
                            Debug.log "Event result" eventResult
                    in
                    ( model, Utils.msgToCmd (OnEventReceived eventResult) )

                OnEventReceived (Ok event) ->
                    let
                        ( newBootModel, bootCmd ) =
                            Boot.update (Boot.OnEventReceived event) bootModel
                    in
                    ( { model | state = BootState newBootModel }
                    , Cmd.batch [ Cmd.map BootMsg bootCmd ]
                    )

                _ ->
                    ( model, Cmd.none )

        GameState gameModel ->
            case msg of
                ClickedLink urlRequest ->
                    ( model, Cmd.none )

                ChangedUrl url ->
                    ( model, Cmd.none )

                BrowserVisibilityChanged _ ->
                    -- We may do more things in the future
                    ( model, Utils.msgToCmd (OSMsg OS.BrowserVisibilityChanged) )

                BrowserMouseUp ->
                    ( model, Utils.msgToCmd (OSMsg OS.StopDrag) )

                -- BrowserResizedViewport v ->
                --     let
                --         debounceConfig =
                --             Debounce.after 100 ResizedViewportDebouncing
                --         ( debounce, cmd ) =
                --             Debounce.push debounceConfig v model.resizeDebouncer
                --     in
                --     ( { model | resizeDebouncer = debounce }, cmd )
                -- ResizedViewportDebounced ( w, h ) ->
                --     ( { model | os = OS.updateViewport model.os ( w, h ) }, Cmd.none )
                -- ResizedViewportDebouncing msg_ ->
                --     let
                --         debounceConfig =
                --             Debounce.after 100 ResizedViewportDebouncing
                --         ( debounce, cmd ) =
                --             Debounce.update
                --                 debounceConfig
                --                 (Debounce.takeLast (Debounce.save ResizedViewportDebounced))
                --                 msg_
                --                 model.resizeDebouncer
                --     in
                --     ( { model | resizeDebouncer = debounce }, cmd )
                OSMsg subMsg ->
                    let
                        ( osModel, osCmd ) =
                            OS.update subMsg gameModel.os
                    in
                    ( { model | state = GameState { os = osModel } }
                    , Cmd.batch [ Cmd.map OSMsg osCmd ]
                    )

                LoginMsg _ ->
                    ( model, Cmd.none )

                BootMsg _ ->
                    ( model, Cmd.none )

                OnRawEventReceived ev ->
                    ( model, Cmd.none )

                OnEventReceived ev ->
                    ( model, Cmd.none )

        InstallState ->
            ( model, Cmd.none )

        ErrorState ->
            ( model, Cmd.none )



-- View


view : Model -> UI.Document Msg
view model =
    case model.state of
        LoginState loginModel ->
            let
                { title, body } =
                    Login.documentView loginModel
            in
            { title = title, body = List.map (Html.map LoginMsg) body }

        GameState gameModel ->
            let
                { title, body } =
                    OS.documentView gameModel.os
            in
            { title = title, body = List.map (Html.map OSMsg) body }

        BootState bootModel ->
            let
                { title, body } =
                    Boot.documentView bootModel
            in
            { title = title, body = List.map (Html.map BootMsg) body }

        _ ->
            { title = "UNHANdled", body = [] }



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.state of
        GameState gameModel ->
            Sub.batch
                [ -- Browser.Events.onResize (\w h -> BrowserResizedViewport ( w, h ))
                  Browser.Events.onVisibilityChange BrowserVisibilityChanged
                , case WM.isDragging gameModel.os.wm of
                    True ->
                        Browser.Events.onMouseUp (JD.succeed BrowserMouseUp)

                    False ->
                        Sub.none
                ]

        _ ->
            eventSubscriber OnRawEventReceived
