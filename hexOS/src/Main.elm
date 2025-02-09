module Main exposing (Flags, Model, Msg(..), init, main, update, view)

import Boot
import Browser
import Browser.Events
import Core.Debounce as Debounce
import Debounce exposing (Debounce)
import Effect exposing (Effect)
import Event exposing (Event)
import Game.Msg as Game
import Game.Universe exposing (Universe(..))
import Html
import Json.Decode as JD
import Login
import OS
import OS.Bus
import Ports
import Random
import State
import TimeTravel.Browser as TimeTravel exposing (defaultConfig)
import UI
import UUID exposing (Seeds)
import Url exposing (Url)
import WM


type Msg
    = ClickedLink Browser.UrlRequest
    | ChangedUrl Url
    | BrowserResizedViewport ( Int, Int )
    | ResizedViewportDebounced ( Int, Int )
    | ResizedViewportDebouncing Debounce.Msg
    | BrowserMouseUp
    | BrowserVisibilityChanged Browser.Events.Visibility
    | GameMsg Game.Msg
    | OSMsg OS.Msg
    | LoginMsg Login.Msg
    | BootMsg Boot.Msg
    | OnRawEventReceived JD.Value
    | OnEventReceived (Result JD.Error Event)


type State
    = LoginState Login.Model
    | BootState Boot.Model
    | GameState State.State OS.Model
    | InstallState
    | ErrorState


{-| `navkey` is a "variable" to the Model in order for it to work with elm-program-test.
-}
type alias Model navkey =
    { seeds : Seeds
    , flags : Flags
    , state : State
    , navKey : navkey
    , resizeDebouncer : Debounce ( Int, Int )
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
    Browser.application
        -- TimeTravel.application Debug.toString
        --     Debug.toString
        -- defaultConfig
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
init flags url__ navKey =
    let
        -- route =
        --     Route.fromUrl url
        -- ( osModel, osCmd ) =
        --     OS.init ( flags.viewportX, flags.viewportY )
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
      , resizeDebouncer = Debounce.init
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
                BootMsg (Boot.ProceedToGame spModel mpModel) ->
                    let
                        -- TODO
                        currentUniverse =
                            Singleplayer

                        wmSessionId =
                            WM.toLocalSessionId spModel.mainframeID

                        ( osModel, osCmd ) =
                            OS.init ( model.flags.viewportX, model.flags.viewportY )

                        ( state, playCmd ) =
                            State.init currentUniverse wmSessionId spModel mpModel
                    in
                    ( { model | state = GameState state osModel }
                    , Effect.batch
                        [ Effect.map GameMsg playCmd
                        , Effect.map OSMsg osCmd
                        ]
                    )

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

                OnEventReceived (Err reason) ->
                    let
                        _ =
                            Debug.log "[Boot] Failed to decode event" reason
                    in
                    ( model, Effect.none )

                _ ->
                    ( model, Effect.none )

        GameState state osModel ->
            case msg of
                ClickedLink _ ->
                    ( model, Effect.none )

                ChangedUrl _ ->
                    ( model, Effect.none )

                BrowserVisibilityChanged _ ->
                    -- We may do more things in the future
                    ( model, Effect.msgToCmd (OSMsg OS.BrowserVisibilityChanged) )

                BrowserMouseUp ->
                    ( model, Effect.msgToCmd (OSMsg OS.StopDrag) )

                BrowserResizedViewport v ->
                    let
                        debounceConfig =
                            Debounce.after 100 ResizedViewportDebouncing

                        ( debounce, cmd ) =
                            Debounce.push debounceConfig v model.resizeDebouncer
                    in
                    ( { model | resizeDebouncer = debounce }, Effect.debouncedCmd cmd )

                ResizedViewportDebouncing msg_ ->
                    let
                        debounceConfig =
                            Debounce.after 100 ResizedViewportDebouncing

                        ( debounce, cmd ) =
                            Debounce.update
                                debounceConfig
                                (Debounce.takeLast (Debounce.save ResizedViewportDebounced))
                                msg_
                                model.resizeDebouncer
                    in
                    ( { model | resizeDebouncer = debounce }, Effect.debouncedCmd cmd )

                ResizedViewportDebounced ( w, h ) ->
                    let
                        newOsModel =
                            OS.updateViewport osModel ( w, h )
                    in
                    ( { model | state = GameState state newOsModel }, Effect.none )

                OSMsg (OS.PerformAction (OS.Bus.ToGame action)) ->
                    ( model, Effect.msgToCmd <| GameMsg (Game.PerformAction action) )

                OSMsg subMsg ->
                    -- NOTE: I'm attempting to keep Game and OS separate and independent of one
                    -- another. Let's see how it goes...
                    let
                        ( newOsModel, osCmd ) =
                            OS.update state subMsg osModel
                    in
                    ( { model | state = GameState state newOsModel }
                    , Effect.batch [ Effect.map OSMsg osCmd ]
                    )

                GameMsg gameMsg ->
                    let
                        ( newState, gameEffect ) =
                            State.update gameMsg state
                    in
                    ( { model | state = GameState newState osModel }
                    , Effect.map GameMsg gameEffect
                    )

                LoginMsg _ ->
                    ( model, Effect.none )

                BootMsg _ ->
                    ( model, Effect.none )

                OnRawEventReceived rawEvent ->
                    let
                        eventResult =
                            Event.processReceivedEvent rawEvent
                    in
                    ( model, Effect.msgToCmd (OnEventReceived eventResult) )

                OnEventReceived (Ok event) ->
                    let
                        ( newState, gameEffect ) =
                            State.update (Game.OnEventReceived event) state
                    in
                    ( { model | state = GameState newState osModel }
                    , Effect.map GameMsg gameEffect
                    )

                OnEventReceived (Err reason) ->
                    let
                        _ =
                            Debug.log "Failed to decode event" reason
                    in
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

        GameState state osModel ->
            -- View in the GameState is entirely controlled by the OS
            let
                { title, body } =
                    OS.documentView state osModel
            in
            { title = title, body = List.map (Html.map OSMsg) body }

        _ ->
            { title = "UNHANdled", body = [] }



-- Subscriptions


subscriptions : Model navkey -> Sub Msg
subscriptions model =
    case model.state of
        GameState state__ osModel ->
            Sub.batch
                [ Browser.Events.onResize (\w h -> BrowserResizedViewport ( w, h ))
                , Browser.Events.onVisibilityChange BrowserVisibilityChanged
                , if WM.isDragging osModel.wm then
                    Browser.Events.onMouseUp (JD.succeed BrowserMouseUp)

                  else
                    Sub.none
                , Ports.eventSubscriber OnRawEventReceived
                ]

        _ ->
            Ports.eventSubscriber OnRawEventReceived
