module UI.Dropdown exposing (..)

{-|


# UI.Dropdown

This is a reimplementation of <select> and <option>

Why? Because I (think I) need more flexibility than what browsers can give me. I'm likely wrong.

TODOs:

  - Keyboard-based navigation
  - Search
  - Support for remote sources

-}

import Effect exposing (Effect)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import UI exposing (UI, cl, style, styleMaybe, text)
import UI.Icon


type Config msg
    = Config (Props msg) Opts


type alias Props msg =
    { entries : List (ConfigEntry msg) }


type alias Opts =
    { maxHeight : Int
    , width : Maybe Int
    }


type alias Model =
    { selected : Maybe String
    , isOpen : Bool
    }


type ConfigEntry msg
    = SelectableEntry (SelectableEntryConfig msg)
    | GroupEntry GroupEntryConfig


type alias SelectableEntryConfig id =
    { label : String
    , opts : Maybe Opts
    , onSelect : Maybe id
    }


type alias GroupEntryConfig =
    { label : String }


type Msg msg
    = Open
    | Close
    | ToggleOpen
    | Selected (SelectableEntryConfig msg)
    | OnSelected msg


init : Maybe String -> Model
init selected =
    { selected = selected
    , isOpen = False
    }


update : Msg msg -> Model -> ( Model, Effect (Msg msg) )
update msg model =
    case msg of
        Open ->
            ( { model | isOpen = True }, Effect.none )

        Close ->
            ( { model | isOpen = False }, Effect.none )

        ToggleOpen ->
            ( { model | isOpen = not model.isOpen }, Effect.none )

        Selected entry ->
            let
                effect =
                    case entry.onSelect of
                        Just msg_ ->
                            Effect.msgToCmd (OnSelected msg_)

                        Nothing ->
                            Effect.none
            in
            ( { model | selected = Just entry.label, isOpen = False }
            , effect
            )

        OnSelected _ ->
            -- This will be handled by the parent
            ( model, Effect.none )


defaultOpts : Opts
defaultOpts =
    { maxHeight = 200
    , width = Nothing
    }


new : List (ConfigEntry msg) -> Config msg
new entries =
    Config { entries = entries } defaultOpts


withMaxHeight : Int -> Config msg -> Config msg
withMaxHeight maxHeight (Config props opts) =
    Config props { opts | maxHeight = maxHeight }


withWidth : Int -> Config msg -> Config msg
withWidth width (Config props opts) =
    Config props { opts | width = Just width }


toUI : Model -> Config msg -> UI (Msg msg)
toUI model (Config { entries } { width, maxHeight }) =
    let
        options =
            if model.isOpen then
                renderOptions model entries

            else
                []

        optionsBlock =
            if model.isOpen then
                UI.col
                    [ cl "ui-dd-options"
                    , style "max-height" <| String.fromInt maxHeight ++ "px"
                    ]
                    options

            else
                UI.emptyEl

        selectionText =
            Maybe.withDefault "Select..." model.selected

        caretDownIcon =
            UI.Icon.msOutline "keyboard_arrow_down" Nothing
                |> UI.Icon.withClass "ui-dd-header-caret"
                |> UI.Icon.toUI

        caretUpIcon =
            UI.Icon.msOutline "keyboard_arrow_up" Nothing
                |> UI.Icon.withClass "ui-dd-header-caret"
                |> UI.Icon.toUI

        header =
            UI.row
                [ cl "ui-dd-header"
                , styleMaybe "width" width (\w -> String.fromInt w ++ "px")
                , UI.onClick ToggleOpen
                ]
                [ H.text selectionText
                , if model.isOpen then
                    caretUpIcon

                  else
                    caretDownIcon
                ]
    in
    UI.col
        [ cl "ui-dropdown" ]
        [ header, optionsBlock ]


renderOptions : Model -> List (ConfigEntry msg) -> List (UI (Msg msg))
renderOptions model entries =
    List.foldr (renderOption model) [] entries


renderOption : Model -> ConfigEntry msg -> List (UI (Msg msg)) -> List (UI (Msg msg))
renderOption model entry acc =
    let
        ( entryClass, label, maybeOnClick ) =
            case entry of
                SelectableEntry entry_ ->
                    ( "ui-dd-selectable-entry", entry_.label, UI.onClick (Selected entry_) )

                GroupEntry entry_ ->
                    ( "ui-dd-group", entry_.label, UI.emptyAttr )

        maybeSelectedClass =
            case ( entry, model.selected ) of
                ( SelectableEntry entry_, Just selectedLabel ) ->
                    if entry_.label == selectedLabel then
                        cl "ui-dd-option-selected"

                    else
                        UI.emptyAttr

                _ ->
                    UI.emptyAttr

        option =
            UI.row
                [ cl "ui-dd-option"
                , cl entryClass
                , maybeSelectedClass
                , maybeOnClick
                ]
                [ H.text label ]
    in
    option :: acc
