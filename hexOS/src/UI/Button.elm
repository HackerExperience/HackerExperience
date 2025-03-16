module UI.Button exposing (..)

import Html as H
import Html.Attributes as HA
import Html.Events as HE
import UI exposing (UI, cl)
import UI.Icon exposing (Icon)


type Config msg
    = Config Props (Opts msg)


type Style
    = StylePrimary
    | StylePrimaryOutline


type alias Props =
    { label : Maybe String
    }


type alias Opts msg =
    { onClick : Maybe msg
    , icon : Maybe (Icon msg)
    , style : Style
    , customClass : Maybe String
    }


new : Maybe String -> Config msg
new label =
    Config { label = label } defaultOpts


fromIcon : Icon msg -> Config msg
fromIcon icon =
    Config { label = UI.Icon.getHint icon }
        { defaultOpts | icon = Just icon }


defaultOpts : Opts msg
defaultOpts =
    { onClick = Nothing
    , icon = Nothing
    , style = StylePrimary
    , customClass = Nothing
    }


toUI : Config msg -> UI msg
toUI (Config props ({ onClick } as opts)) =
    H.button
        [ cl "ui-button"
        , getStyleClass opts.style |> cl
        , case opts.customClass of
            Just customClass ->
                cl customClass

            Nothing ->
                UI.emptyAttr
        , case onClick of
            Just msg ->
                HE.onClick msg

            Nothing ->
                -- NOTE: This `HA.disabled` is causing `contextmenu` event to bypass stopPropagation
                HA.disabled True
        ]
        [ body props opts ]


body : Props -> Opts msg -> UI msg
body { label } { icon } =
    case ( icon, label ) of
        ( Just icon_, Just label_ ) ->
            UI.row [ cl "ui-button-landi" ]
                [ UI.Icon.toUI icon_
                , UI.text label_
                ]

        ( Just icon_, Nothing ) ->
            UI.row [ cl "ui-button-ionly" ]
                [ UI.Icon.toUI icon_ ]

        ( Nothing, Just label_ ) ->
            UI.text label_

        ( Nothing, Nothing ) ->
            UI.text "Botao sem label"


withOnClick : msg -> Config msg -> Config msg
withOnClick msg (Config props opts) =
    Config props { opts | onClick = Just msg }


withLabel : Maybe String -> Config msg -> Config msg
withLabel label (Config props opts) =
    Config { props | label = label } opts


withClass : String -> Config msg -> Config msg
withClass class (Config props opts) =
    Config props { opts | customClass = Just class }


withStyle : Style -> Config msg -> Config msg
withStyle style (Config props opts) =
    Config props { opts | style = style }


getStyleClass : Style -> String
getStyleClass style =
    case style of
        StylePrimary ->
            "ui-button-primary"

        StylePrimaryOutline ->
            "ui-button-primary-outline"
