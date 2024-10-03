module UI.TextInput exposing (..)

import Html as H
import Html.Attributes as HA
import Html.Events as HE
import UI exposing (UI, cl)
import UI.Icon exposing (Icon)


type Input msg
    = Input Props (Opts msg)


type alias Props =
    { label : String
    , value : String
    , kind : String
    }


type alias Opts msg =
    { onChange : Maybe (String -> msg)
    , onBlur : Maybe msg
    , placeholder : Maybe String
    , icon : Maybe (Icon msg)
    , problem : Maybe String
    }


new : String -> String -> Input msg
new label value =
    Input
        { label = label
        , value = value
        , kind = "text"
        }
        { defaultOpts | placeholder = Just label }


fromIcon : String -> Icon msg -> Input msg
fromIcon value icon =
    Input
        { label = Maybe.withDefault "" (UI.Icon.getHint icon)
        , value = value
        , kind = "text"
        }
        { defaultOpts | icon = Just icon }



-- Opts


withOnChange : (String -> msg) -> Input msg -> Input msg
withOnChange msg (Input props opts) =
    Input props { opts | onChange = Just msg }


withOnBlur : msg -> Input msg -> Input msg
withOnBlur msg (Input props opts) =
    Input props { opts | onBlur = Just msg }


withPasswordType : Input msg -> Input msg
withPasswordType (Input props opts) =
    Input { props | kind = "password" } opts


withProblem : Maybe String -> Input msg -> Input msg
withProblem maybeProblem (Input props opts) =
    Input props { opts | problem = maybeProblem }


defaultOpts : Opts msg
defaultOpts =
    { onChange = Nothing
    , onBlur = Nothing
    , placeholder = Nothing
    , icon = Nothing
    , problem = Nothing
    }



-- View


toUI : Input msg -> UI msg
toUI ((Input _ { icon }) as input) =
    let
        inputRow =
            case icon of
                Just icon_ ->
                    [ inputIcon icon_
                    , inputUI input
                    ]

                Nothing ->
                    [ inputUI input ]
    in
    UI.col []
        [ UI.row [ cl "ui-input-text-row" ]
            inputRow
        , inputDescUI input
        ]


inputUI : Input msg -> UI msg
inputUI (Input { label, value, kind } { onChange, onBlur, placeholder, problem }) =
    H.input
        [ cl "ui-input-text"
        , HA.type_ kind
        , HA.value value
        , HA.title label
        , attrProblem problem
        , attrPlaceholder placeholder
        , case onChange of
            Just msg ->
                HE.onInput msg

            Nothing ->
                UI.emptyAttr
        , case onBlur of
            Just msg ->
                HE.onBlur msg

            Nothing ->
                UI.emptyAttr
        ]
        []


inputDescUI : Input msg -> UI msg
inputDescUI (Input _ { problem }) =
    -- TODO: Also support showing info desc on focus (or maybe always -- not only on focus)
    case problem of
        Just probleminha ->
            UI.row [ cl "ui-input-text-desc ui-input-text-desc-problem" ]
                [ UI.text probleminha ]

        Nothing ->
            UI.emptyEl


attrPlaceholder : Maybe String -> UI.Attribute msg
attrPlaceholder placeholder =
    case placeholder of
        Just v ->
            HA.placeholder v

        Nothing ->
            UI.emptyAttr


attrProblem : Maybe String -> UI.Attribute msg
attrProblem problem =
    case problem of
        Just _ ->
            cl "ui-input-text-problem"

        Nothing ->
            UI.emptyAttr


inputIcon : Icon msg -> UI msg
inputIcon icon =
    UI.Icon.toUI icon
