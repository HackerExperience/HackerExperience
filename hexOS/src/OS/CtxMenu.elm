module OS.CtxMenu exposing
    ( Config
    , ConfigEntry(..)
    , Model
    , Msg(..)
    , event
    , initialModel
    , noop
    , noopSelf
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
    | Open Float Float Menu
    | OnCtxMenuEnter
    | OnCtxMenuLeave
    | Close


type alias Model =
    { openMenu : Maybe Menu
    , posX : Float
    , posY : Float
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


initialModel : Model
initialModel =
    { openMenu = Nothing
    , posX = 0
    , posY = 0
    , isHovered = False
    }



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
            (JD.field "clientX" JD.float)
            (JD.field "clientY" JD.float)



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
    in
    col
        [ id "os-ctx-menu"
        , UI.style "top" <| String.fromFloat model.posY ++ "px"
        , UI.style "left" <| String.fromFloat model.posX ++ "px"
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
        -- TODO: Decide between onClick and onMouseDown. UX issues with other areas that are
        -- stopping propagation (close window; drag window; open CI selector)
        Browser.Events.onMouseDown (JD.succeed Close)

    else
        Sub.none
