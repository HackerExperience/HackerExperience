module UI.Icon exposing (..)

import Html as H
import Html.Events as HE
import UI exposing (UI, cl)


type Icon msg
    = Icon Props (Opts msg)


type Provider
    = MSOutline
    | FABrands


type alias Props =
    { hint : Maybe String
    , glyph : String
    , provider : Provider
    }


type alias Opts msg =
    { spin : Bool
    , onClick : Maybe msg
    , class : Maybe String
    }


defaultOpts : Opts msg
defaultOpts =
    { spin = False
    , onClick = Nothing
    , class = Nothing
    }


getHint : Icon msg -> Maybe String
getHint (Icon { hint } _) =
    hint


getProvider : Icon msg -> Provider
getProvider (Icon { provider } _) =
    provider


withOnClick : msg -> Icon msg -> Icon msg
withOnClick msg (Icon props opts) =
    Icon props { opts | onClick = Just msg }


withClass : String -> Icon msg -> Icon msg
withClass class (Icon props opts) =
    Icon props { opts | class = Just class }


toUI : Icon msg -> UI msg
toUI icon =
    case getProvider icon of
        MSOutline ->
            toUIMSOutline icon

        FABrands ->
            toUIFABrands icon



-- TODO: Support spin, color etc


toUIMSOutline : Icon msg -> UI msg
toUIMSOutline (Icon { glyph } { class, onClick }) =
    H.span
        [ cl "ui-icon material-symbols-outlined"
        , maybeAddCustomClass class
        , maybeAddClickHandler onClick
        ]
        [ H.text glyph ]


toUIFABrands : Icon msg -> UI msg
toUIFABrands (Icon { glyph } _) =
    H.i
        [ cl "ui-icon fab"
        , "fa-" ++ glyph |> cl
        ]
        []


maybeAddClickHandler : Maybe msg -> UI.Attribute msg
maybeAddClickHandler onClick =
    case onClick of
        Just msg ->
            HE.onClick msg

        Nothing ->
            UI.emptyAttr


maybeAddCustomClass : Maybe String -> UI.Attribute msg
maybeAddCustomClass class =
    case class of
        Just class_ ->
            cl class_

        Nothing ->
            UI.emptyAttr



-- Icons:
-- FABrands:


iCloudflare : Maybe String -> Icon msg
iCloudflare hint =
    Icon (Props hint "instagram" FABrands) defaultOpts



-- MSOutline:


msOutline : String -> Maybe String -> Icon msg
msOutline name hint =
    Icon (Props hint name MSOutline) defaultOpts


iAdd : Maybe String -> Icon msg
iAdd hint =
    Icon (Props hint "add" MSOutline) defaultOpts


iCheck : Maybe String -> Icon msg
iCheck hint =
    Icon (Props hint "check" MSOutline) defaultOpts


iClose : Maybe String -> Icon msg
iClose hint =
    Icon (Props hint "close" MSOutline) defaultOpts


iFilter : Maybe String -> Icon msg
iFilter hint =
    Icon (Props hint "filter_alt" MSOutline) defaultOpts


iGroup : Maybe String -> Icon msg
iGroup hint =
    Icon (Props hint "group" MSOutline) defaultOpts


iPersonAdd : Maybe String -> Icon msg
iPersonAdd hint =
    Icon (Props hint "person_add" MSOutline) defaultOpts


iRemove : Maybe String -> Icon msg
iRemove hint =
    Icon (Props hint "remove" MSOutline) defaultOpts


iSavedSearch : Maybe String -> Icon msg
iSavedSearch hint =
    Icon (Props hint "saved_search" MSOutline) defaultOpts


iSearch : Maybe String -> Icon msg
iSearch hint =
    Icon (Props hint "search" MSOutline) defaultOpts
