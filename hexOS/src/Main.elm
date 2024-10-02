module Main exposing (Flags, Msg(..), init, main, update, view, wrapInit, wrapUpdate)

import Boot
import Browser
import Browser.Events
import Browser.Navigation as Nav
import Core.Debounce as Debounce
import Debounce exposing (Debounce)
import Dict exposing (Dict)
import Effect exposing (Effect)
import Event exposing (Event)
import Game
import Game.Universe
import Html exposing (Html)
import Json.Decode as JD
import Login
import OS
import Ports
import Process
import Random
import Result
import Task
import TimeTravel.Browser as TimeTravel exposing (defaultConfig)
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
    | GameMsg Game.Msg
      -- Note: nao existe OSMsg aqui; somente em GameMsg OsMsg
    | OSMsg OS.Msg
    | LoginMsg Login.Msg
    | BootMsg Boot.Msg
    | OnRawEventReceived String
    | OnEventReceived (Result JD.Error Event)


type State
    = LoginState Login.Model
    | BootState Boot.Model
    | GameState Game.Model
    | InstallState
    | ErrorState


{-| `navkey` is a "variable" to the Model in order for it to work with elm-program-test.
-}
type alias Model navkey =
    { seeds : Seeds
    , flags : Flags
    , state : State
    , navKey : navkey

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



-- Main


{-| NOTE: I'll experiment developing with `elm-time-travel` debugger instead of the official one.
For prod, we need to replace `TimeTravel.application` with `Browser.application`.

main : Program Flags Model Msg

-}
main =
    -- Browser.application
    TimeTravel.application Debug.toString
        Debug.toString
        defaultConfig
        { init = wrapInit
        , view = view
        , update = wrapUpdate
        , subscriptions = subscriptions
        , onUrlRequest = ClickedLink
        , onUrlChange = ChangedUrl
        }



-- Model


wrapInit : Flags -> Url -> navkey -> ( Model navkey, Cmd Msg )
wrapInit flags url navKey =
    let
        ( model, effects ) =
            init flags url navKey

        ( newSeeds, cmds ) =
            Effect.apply ( model.seeds, effects )
    in
    ( { model | seeds = newSeeds }, cmds )


init : Flags -> Url -> navkey -> ( Model navkey, Effect Msg )
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
      , flags = flags
      , state = LoginState Login.initialModel
      , navKey = navKey

      -- , resizeDebouncer = Debounce.init
      }
      -- , Cmd.batch
      --     [ Cmd.map OSMsg osCmd
      --     ]
    , Effect.none
    )



-- Update


wrapUpdate : Msg -> Model navkey -> ( Model navkey, Cmd Msg )
wrapUpdate msg model =
    let
        ( newModel, effects ) =
            update msg model

        ( newSeeds, cmds ) =
            Effect.apply ( newModel.seeds, effects )
    in
    ( { newModel | seeds = newSeeds }, cmds )


update : Msg -> Model navkey -> ( Model navkey, Effect Msg )
update msg model =
    case model.state of
        LoginState loginModel ->
            case msg of
                LoginMsg (Login.ProceedToBoot token) ->
                    let
                        ( bootModel, bootCmd ) =
                            Boot.init token
                    in
                    ( { model | state = BootState bootModel }, Effect.map BootMsg bootCmd )

                LoginMsg subMsg ->
                    let
                        ( newLoginModel, loginCmd ) =
                            Login.update subMsg loginModel
                    in
                    ( { model | state = LoginState newLoginModel }
                    , Effect.batch [ Effect.map LoginMsg loginCmd ]
                    )

                _ ->
                    ( model, Effect.none )

        BootState bootModel ->
            case msg of
                BootMsg (Boot.ProceedToGame spModel) ->
                    let
                        ( osModel, osCmd ) =
                            OS.init ( model.flags.viewportX, model.flags.viewportY )

                        ( gameModel, playCmd ) =
                            Game.init spModel osModel
                    in
                    ( { model | state = GameState gameModel }
                    , Effect.batch
                        [ Effect.map GameMsg playCmd
                        , Effect.map OSMsg osCmd
                        ]
                    )

                BootMsg Boot.EstablishSSEConnection ->
                    ( model, Effect.sseStart bootModel.token )

                BootMsg subMsg ->
                    let
                        ( newBootModel, bootCmd ) =
                            Boot.update subMsg bootModel
                    in
                    ( { model | state = BootState newBootModel }
                    , Effect.batch [ Effect.map BootMsg bootCmd ]
                    )

                OnRawEventReceived rawEvent ->
                    let
                        eventResult =
                            Event.processReceivedEvent rawEvent

                        _ =
                            Debug.log "Event result" eventResult
                    in
                    ( model, Effect.msgToCmd (OnEventReceived eventResult) )

                OnEventReceived (Ok event) ->
                    let
                        ( newBootModel, bootCmd ) =
                            Boot.update (Boot.OnEventReceived event) bootModel
                    in
                    ( { model | state = BootState newBootModel }
                    , Effect.batch [ Effect.map BootMsg bootCmd ]
                    )

                _ ->
                    ( model, Effect.none )

        GameState gameModel ->
            case msg of
                ClickedLink urlRequest ->
                    ( model, Effect.none )

                ChangedUrl url ->
                    ( model, Effect.none )

                BrowserVisibilityChanged _ ->
                    -- We may do more things in the future
                    ( model, Effect.msgToCmd (OSMsg OS.BrowserVisibilityChanged) )

                BrowserMouseUp ->
                    ( model, Effect.msgToCmd (OSMsg OS.StopDrag) )

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
                    -- NOTE: I'm attempting to keep Game and OS separate and independent of one
                    -- another. Let's see how it goes...
                    let
                        ( osModel, osCmd ) =
                            OS.update subMsg gameModel.os
                    in
                    ( { model | state = GameState { gameModel | os = osModel } }
                    , Effect.batch [ Effect.map OSMsg osCmd ]
                    )

                GameMsg subMsg ->
                    ( model, Effect.none )

                LoginMsg _ ->
                    ( model, Effect.none )

                BootMsg _ ->
                    ( model, Effect.none )

                OnRawEventReceived ev ->
                    ( model, Effect.none )

                OnEventReceived ev ->
                    ( model, Effect.none )

        InstallState ->
            ( model, Effect.none )

        ErrorState ->
            ( model, Effect.none )



-- View


view : Model navkey -> UI.Document Msg
view model =
    case model.state of
        LoginState loginModel ->
            let
                { title, body } =
                    Login.documentView loginModel
            in
            { title = title, body = List.map (Html.map LoginMsg) body }

        BootState bootModel ->
            let
                { title, body } =
                    Boot.documentView bootModel
            in
            { title = title, body = List.map (Html.map BootMsg) body }

        GameState gameModel ->
            -- View in the GameState is entirely controlled by the OS
            let
                { title, body } =
                    OS.documentView gameModel.os
            in
            { title = title, body = List.map (Html.map OSMsg) body }

        _ ->
            { title = "UNHANdled", body = [] }



-- Subscriptions


subscriptions : Model navkey -> Sub Msg
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
            Ports.eventSubscriber OnRawEventReceived
