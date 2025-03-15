module OS.CtxMenu exposing
    ( Config
    , ConfigEntry(..)
    , Model
    , Msg(..)
    , event
    , initialModel
    , noop
    , noopSelf
    , setViewport
    , subscriptions
    , update
    , view
    )

import Browser.Events
import Effect exposing (Effect)
import Html.Events as HE
import Json.Decode as JD
import Maybe.Extra as Maybe
import OS.CtxMenu.Menus exposing (Menu)
import UI exposing (UI, cl, col, id, row, text)



-- Types


type Msg
    = NoOp
    | Open Int Int Menu
    | OnCtxMenuEnter
    | OnCtxMenuLeave
    | Close


type alias Model =
    { openMenu : Maybe Menu
    , posX : Int
    , posY : Int
    , viewportX : Int
    , viewportY : Int
    , isHovered : Bool
    }


type ConfigEntry msg
    = SimpleItem (SimpleItemConfig msg)
    | Divisor


type alias SimpleItemConfig msg =
    { label : String
    , enabled : Bool
    , onClick : Maybe msg
    }


type alias Config msg =
    { entries : List (ConfigEntry msg)
    , mapper : Msg -> msg
    }



-- Model


initialModel : ( Int, Int ) -> Model
initialModel ( viewportX, viewportY ) =
    { openMenu = Nothing
    , posX = 0
    , posY = 0
    , viewportX = viewportX
    , viewportY = viewportY
    , isHovered = False
    }


setViewport : Model -> ( Int, Int ) -> Model
setViewport model ( viewportX, viewportY ) =
    { model | viewportX = viewportX, viewportY = viewportY }


calculateMenuPosition : Model -> Config msg -> ( Int, Int )
calculateMenuPosition { posX, posY, viewportX, viewportY } config =
    let
        inferredMenuHeight =
            ceiling <| calculateMenuHeight config

        inferredMenuWidth =
            200

        offsetX =
            viewportX - posX

        offsetY =
            viewportY - posY

        newPosY =
            if offsetY < inferredMenuHeight then
                viewportY - inferredMenuHeight - offsetY

            else
                posY

        newPosX =
            if offsetX < inferredMenuWidth then
                viewportX - inferredMenuWidth - offsetX

            else
                posX
    in
    ( newPosX, newPosY )


{-| The goal of this function is to calculate / infer the height of the context menu _before_ it
gets rendered. We need to know it (beforehand) in order to know where to render it (if in the bottom
right direction, which is the default, or alternative directions, like top right or top left or
bottom right).

If after render, we could simply ask DOM for the full height of the node. We can't (unless we render
it hidden, at first, and then make it visible afterwards, which is not a bad idea per se). As such,
we are simply "inferring" what the likely height will be, based on the contents of the menu.

This works very well, however it is prone to changes in the CSS file (e.g. increased padding)
silently breaking the functionality of positional rendering of the Context Menu. It will still
render just fine, but possibly in the wrong location.

The other caveat is that this will break under different zoom levels, fonts etc. Really, we should
render it off-screen / with hidden visibility, calculate the height and then make it visible. This
is TODO for now.

-}
calculateMenuHeight : Config msg -> Float
calculateMenuHeight config =
    let
        getEntryHeight =
            \entry ->
                case entry of
                    SimpleItem _ ->
                        29

                    Divisor ->
                        17
    in
    List.foldl
        (\entry acc -> acc + getEntryHeight entry)
        2
        config.entries



-- Update


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        Open posX posY menu ->
            ( { model | openMenu = Just menu, posX = posX, posY = posY }
            , Effect.none
            )

        Close ->
            ( { model | openMenu = Nothing, isHovered = False }, Effect.none )

        OnCtxMenuEnter ->
            ( { model | isHovered = True }, Effect.none )

        OnCtxMenuLeave ->
            ( { model | isHovered = False }, Effect.none )

        NoOp ->
            ( model, Effect.none )



-- Events API


noop : UI.Attribute Msg
noop =
    HE.custom "contextmenu" <|
        JD.succeed { message = Close, preventDefault = True, stopPropagation = True }


noopSelf : msg -> UI.Attribute msg
noopSelf msg =
    HE.custom "contextmenu" <|
        JD.succeed { message = msg, preventDefault = True, stopPropagation = True }


event : Menu -> UI.Attribute Msg
event menu =
    HE.custom "contextmenu" <|
        JD.map2 (\x y -> { message = Open x y menu, preventDefault = True, stopPropagation = True })
            (JD.field "clientX" JD.int)
            (JD.field "clientY" JD.int)



-- View


view : Model -> (Msg -> msg) -> (Menu -> a -> Maybe (Config msg)) -> a -> UI msg
view model msgMap getConfig a =
    case model.openMenu of
        Just menu ->
            case getConfig menu a of
                Just config ->
                    renderMenu model msgMap config

                Nothing ->
                    UI.emptyEl

        Nothing ->
            UI.emptyEl


renderMenu : Model -> (Msg -> msg) -> Config msg -> UI msg
renderMenu model msgMap config =
    let
        entries =
            List.foldr (renderEntry config) [] config.entries

        ( posLeft, posTop ) =
            calculateMenuPosition model config
    in
    col
        [ id "os-ctx-menu"
        , UI.style "top" <| String.fromInt posTop ++ "px"
        , UI.style "left" <| String.fromInt posLeft ++ "px"
        , HE.onMouseEnter (msgMap OnCtxMenuEnter)
        , HE.onMouseLeave (msgMap OnCtxMenuLeave)
        ]
        entries


renderEntry : Config msg -> ConfigEntry msg -> List (UI msg) -> List (UI msg)
renderEntry config configEntry acc =
    case configEntry of
        SimpleItem item ->
            let
                onClickAttr =
                    case ( item.enabled, item.onClick ) of
                        ( True, Just msg ) ->
                            UI.onClick msg

                        _ ->
                            UI.emptyAttr

                onMouseUpAttr =
                    case ( item.enabled, item.onClick ) of
                        ( True, Just _ ) ->
                            HE.on "mouseup" <|
                                JD.map
                                    (\button ->
                                        -- Only close the menu when "mouseup" is from the left click
                                        if button == 0 then
                                            config.mapper Close

                                        else
                                            config.mapper NoOp
                                    )
                                    (JD.field "button" JD.int)

                        _ ->
                            UI.emptyAttr

                maybeDisabledClass =
                    if not item.enabled then
                        cl "os-cm-simple-item-disabled"

                    else
                        UI.emptyAttr
            in
            row
                [ cl "os-cm-simple-item-area"
                , maybeDisabledClass
                , onClickAttr
                , onMouseUpAttr
                ]
                [ text item.label ]
                :: acc

        Divisor ->
            row [ cl "os-cm-divisor-area" ] [ UI.hr ] :: acc



-- Subscriptions


isOpen : Model -> Bool
isOpen { openMenu } =
    Maybe.isJust openMenu


subscriptions : Model -> Sub Msg
subscriptions model =
    if isOpen model && not model.isHovered then
        Browser.Events.onMouseDown (JD.succeed Close)

    else
        Sub.none
