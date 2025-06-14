module UI exposing (..)

import Browser
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Html.Keyed as Keyed
import Html.Lazy as Lazy


type alias Document msg =
    Browser.Document msg


type alias InnerDocument msg =
    { body : UI msg, title : String }


type alias UI msg =
    Html msg


type alias Attribute msg =
    H.Attribute msg



--------------------------------------------------------------------------------
-- DOM
--------------------------------------------------------------------------------


row : List (Attribute msg) -> List (Html msg) -> Html msg
row attrs children =
    H.div
        (cl "ui-row" :: attrs)
        children


col : List (Attribute msg) -> List (Html msg) -> Html msg
col attrs children =
    H.div
        (cl "ui-col" :: attrs)
        children


div : List (Attribute msg) -> List (Html msg) -> Html msg
div attrs children =
    H.div
        attrs
        children


link : List (Attribute msg) -> List (Html msg) -> String -> Html msg
link attrs child url =
    H.a
        (cl "ui-link" :: HA.href url :: attrs)
        child


cl : String -> Attribute msg
cl name =
    HA.class name


maybeCl : Maybe String -> Attribute msg
maybeCl maybeName =
    case maybeName of
        Just name ->
            cl name

        Nothing ->
            emptyAttr


clIf : Bool -> String -> Attribute msg
clIf condition name =
    if condition then
        cl name

    else
        emptyAttr


id : String -> Attribute msg
id name =
    HA.id name


style : String -> String -> Attribute msg
style property value =
    HA.style property value


maybeStyle : String -> Maybe x -> (x -> String) -> Attribute msg
maybeStyle property maybeValue extractor =
    case maybeValue of
        Just v ->
            style property (extractor v)

        Nothing ->
            emptyAttr


text : String -> Html msg
text val =
    H.span [ cl "ui-span" ] [ H.text val ]


hr : Html msg
hr =
    H.hr [] []


img : String -> Html msg
img src =
    H.img [ HA.src src ] []


attr : String -> String -> Attribute msg
attr name value =
    HA.attribute name value


emptyAttr : Attribute msg
emptyAttr =
    cl ""


emptyEl : Html msg
emptyEl =
    H.text ""



--------------------------------------------------------------------------------
-- DOM > Keyed
--------------------------------------------------------------------------------


keyedCol : List (Attribute msg) -> List ( String, UI msg ) -> Html msg
keyedCol attrs keyedEntries =
    flexKeyed "ui-col" attrs keyedEntries


keyedRow : List (Attribute msg) -> List ( String, UI msg ) -> Html msg
keyedRow attrs keyedEntries =
    flexKeyed "ui-row" attrs keyedEntries


flexKeyed : String -> List (Attribute msg) -> List ( String, UI msg ) -> Html msg
flexKeyed flexClass attrs keyedEntries =
    Keyed.node
        "div"
        (cl flexClass :: attrs)
        keyedEntries



--------------------------------------------------------------------------------
-- DOM > Lazy
--------------------------------------------------------------------------------


lazy : (a -> Html msg) -> a -> Html msg
lazy f a =
    Lazy.lazy f a


lazy2 : (a -> b -> Html msg) -> a -> b -> Html msg
lazy2 f a b =
    Lazy.lazy2 f a b


lazy3 : (a -> b -> c -> Html msg) -> a -> b -> c -> Html msg
lazy3 f a b c =
    Lazy.lazy3 f a b c


lazy4 : (a -> b -> c -> d -> Html msg) -> a -> b -> c -> d -> Html msg
lazy4 f a b c d =
    Lazy.lazy4 f a b c d



--------------------------------------------------------------------------------
-- Class helpers / utils
--------------------------------------------------------------------------------


centerItems : Attribute msg
centerItems =
    cl "ui-align-items"


centerXY : Attribute msg
centerXY =
    cl "ui-center-xy"


flexFill : Attribute msg
flexFill =
    cl "ui-flex-fill"


flexGrow : Attribute msg
flexGrow =
    cl "ui-flex-grow-1"


hide : Attribute msg
hide =
    cl "ui-hide"


widthFill : Attribute msg
widthFill =
    cl "ui-width-fill"


heightFill : Attribute msg
heightFill =
    cl "ui-height-fill"


pointer : Attribute msg
pointer =
    cl "ui-cursor-pointer"



-- Events (TODO see if that's the API I want to use)


onClick : msg -> Attribute msg
onClick msg =
    HE.onClick msg
