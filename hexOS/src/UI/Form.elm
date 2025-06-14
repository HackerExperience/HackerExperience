module UI.Form exposing (..)

import Html as H
import Html.Attributes as HA
import UI exposing (UI, cl, clMaybe)
import UI.Icon exposing (Icon)


type FieldLabelConfig msg
    = FieldLabelConfig FieldLabelProps (FieldLabelOpts msg)


type alias FieldLabelProps =
    { label : String
    }


type alias FieldLabelOpts msg =
    { onHover : Maybe msg }


type FieldPairConfig msg
    = FieldPairConfig (FieldPairProps msg) FieldPairOpts


type alias FieldPairProps msg =
    { left : UI msg
    , right : UI msg
    }


type alias FieldPairOpts =
    { customClass : Maybe String }



-- FieldLabel


newFieldLabel : String -> FieldLabelConfig msg
newFieldLabel label =
    FieldLabelConfig { label = label } fieldLabelDefaultOpts


fieldLabelDefaultOpts : FieldLabelOpts msg
fieldLabelDefaultOpts =
    { onHover = Nothing }


fieldLabelToUI : FieldLabelConfig msg -> UI msg
fieldLabelToUI (FieldLabelConfig { label } _) =
    H.span [ cl "ui-field-label" ]
        [ H.text label ]



-- FieldPair


newFieldPair : UI msg -> UI msg -> FieldPairConfig msg
newFieldPair left right =
    FieldPairConfig { left = left, right = right } fieldPairDefaultOpts


fieldPairWithClass : String -> FieldPairConfig msg -> FieldPairConfig msg
fieldPairWithClass class (FieldPairConfig props opts) =
    FieldPairConfig props { opts | customClass = Just class }


fieldPairDefaultOpts : FieldPairOpts
fieldPairDefaultOpts =
    { customClass = Nothing }


fieldPairToUI : FieldPairConfig msg -> UI msg
fieldPairToUI (FieldPairConfig { left, right } { customClass }) =
    UI.row
        [ cl "ui-field-pair"
        , clMaybe customClass
        ]
        [ left, right ]
