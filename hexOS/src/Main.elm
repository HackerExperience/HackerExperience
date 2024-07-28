module Main exposing (main)

import Browser
import Browser.Events
import Browser.Navigation as Nav
import Core.Debounce as Debounce
import Debounce exposing (Debounce)
import Dict exposing (Dict)
import Html exposing (Html)
import Json.Decode as JD
import OS
import Process
import Random
import Task
import UI exposing (UI)
import UUID exposing (Seeds, UUID)
import Url exposing (Url)
import Utils
import WM


type Msg
    = ClickedLink Browser.UrlRequest
    | ChangedUrl Url
    | BrowserResizedViewport ( Int, Int )
    | ResizedViewportDebounced ( Int, Int )
    | ResizedViewportDebouncing Debounce.Msg
    | BrowserMouseUp
    | BrowserVisibilityChanged Browser.Events.Visibility
    | OSMsg OS.Msg


type alias Model =
    { seeds : Seeds
    , os : OS.Model
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

        ( osModel, osCmd ) =
            OS.init (flags.viewportX, flags.viewportY)

        firstSeeds =
            Seeds
                (Random.initialSeed flags.randomSeed1)
                (Random.initialSeed flags.randomSeed2)
                (Random.initialSeed flags.randomSeed3)
                (Random.initialSeed flags.randomSeed4)
    in
    ( { seeds = firstSeeds
      , os = osModel
      , resizeDebouncer = Debounce.init
      }
    , Cmd.batch
        [ Cmd.map OSMsg osCmd
        ]
    )



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
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

        BrowserResizedViewport v ->
            let
                debounceConfig =
                    Debounce.after 100 ResizedViewportDebouncing

                ( debounce, cmd ) =
                    Debounce.push debounceConfig v model.resizeDebouncer
            in
            ( { model | resizeDebouncer = debounce }, cmd )

        ResizedViewportDebounced ( w, h ) ->
            ( { model | os = OS.updateViewport model.os ( w, h ) }, Cmd.none )

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
            ( { model | resizeDebouncer = debounce }, cmd )

        OSMsg subMsg ->
            let
                ( osModel, osCmd ) =
                    OS.update subMsg model.os
            in
            ( { model | os = osModel }
            , Cmd.batch [ Cmd.map OSMsg osCmd ]
            )



-- View


view : Model -> UI.Document Msg
view model =
    let
        { title, body } =
            OS.documentView model.os
    in
    { title = title, body = List.map (Html.map OSMsg) body }



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onResize (\w h -> BrowserResizedViewport ( w, h ))
        , Browser.Events.onVisibilityChange BrowserVisibilityChanged
        , case WM.isDragging model.os.wm of
            True ->
                Browser.Events.onMouseUp (JD.succeed BrowserMouseUp)

            False ->
                Sub.none
        ]