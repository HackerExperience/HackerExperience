module Apps.Popups.ConfirmationPrompt exposing (..)

import Apps.Input as App
import Apps.Manifest as App
import Apps.Popups.ConfirmationPrompt.Types exposing (Action(..), ActionOption(..), Msg(..))
import Effect exposing (Effect)
import OS.AppID exposing (AppID)
import OS.Bus
import UI exposing (UI, cl, col, row, text)
import UI.Button
import WM


type alias Model =
    { body : UI Msg
    , actionOption : ActionOption
    }



-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ToParent _ ->
            -- Handled by os
            ( model, Effect.none )



-- View


view : Model -> UI Msg
view model =
    -- TODO: Consider presets for apps that share the same body/actionRow structure
    col [ cl "popup-confirmationprompt" ]
        [ vBody model
        , vActionRow model
        ]


vBody : Model -> UI Msg
vBody model =
    row [ cl "p-cop-body" ]
        [ model.body ]


vActionRow : Model -> UI Msg
vActionRow model =
    case model.actionOption of
        ActionConfirmCancel cancelLabel confirmLabel ->
            vActionRowConfirmCancel cancelLabel confirmLabel

        ActionConfirmOnly _ ->
            text "todo"


vActionRowConfirmCancel : String -> String -> UI Msg
vActionRowConfirmCancel cancelLabel confirmLabel =
    row [ cl "p-cop-actionrow" ]
        [ row [ cl "p-cop-ar-left-area" ] [ vButton cancelLabel Cancel ]
        , row [ cl "p-cop-ar-right" ] [ vButton confirmLabel Confirm ]
        ]


vButton : String -> Action -> UI Msg
vButton label action =
    let
        -- TODO: Better UX, show spinner etc
        button =
            UI.Button.new (Just label)
                |> UI.Button.withClass "p-cop-ar-btn"
                |> UI.Button.withOnClick (ToParent action)
                |> UI.Button.toUI
    in
    row [ cl "p-cop-ar-buttonarea" ]
        [ button ]



-- OS.Dispatcher callbacks


getWindowConfig : WM.WindowInfo -> WM.WindowConfig
getWindowConfig _ =
    { lenX = 400
    , lenY = 400
    , title = "Confirmation Prompt"
    , childBehavior = Nothing
    , misc =
        Just
            { vibrateOnOpen = True
            }
    }


willOpen : WM.WindowInfo -> App.InitialInput -> OS.Bus.Action
willOpen window input =
    OS.Bus.OpenApp App.PopupConfirmationPrompt window.parent input


didOpen : WM.WindowInfo -> App.InitialInput -> ( Model, Effect Msg )
didOpen _ input =
    let
        ( body, actionOption ) =
            case input of
                App.PopupConfirmationPromptInput ( body_, actionOption_ ) ->
                    ( body_, actionOption_ )

                _ ->
                    ( text "<Invalid input type>", ActionConfirmOnly "Ok" )
    in
    ( { body = body, actionOption = actionOption }, Effect.none )


willClose : AppID -> Model -> WM.Window -> OS.Bus.Action
willClose appId _ _ =
    OS.Bus.CloseApp appId


willFocus : AppID -> WM.Window -> OS.Bus.Action
willFocus appId _ =
    OS.Bus.FocusApp appId
