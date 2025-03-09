module OS.CtxMenu exposing
    ( Config
    , ConfigEntry(..)
    , Model
    , Msg(..)
    , event
    , initialModel
    , noop
    , subscriptions
    , update
    , view
    )

import Browser.Events
import Effect exposing (Effect)
import Html.Events as HE
import Json.Decode as JD
import Maybe.Extra as Maybe
import UI exposing (UI, cl, col, div, id, row, text)



-- Types


type Msg menu
    = NoOp
    | Open Float Float menu
    | OnCtxMenuEnter
    | OnCtxMenuLeave
    | Close


type alias Model menu =
    { openMenu : Maybe menu
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


type alias Config msg menu =
    { entries : List (ConfigEntry msg)
    , mapper : Msg menu -> msg
    }



-- Model


initialModel : Model menu
initialModel =
    { openMenu = Nothing
    , posX = 0
    , posY = 0
    , isHovered = False
    }



-- Update


update : Msg menu -> Model menu -> ( Model menu, Effect (Msg menu) )
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


noop : UI.Attribute (Msg menu)
noop =
    HE.custom "contextmenu" <|
        JD.map2 (\x y -> { message = NoOp, preventDefault = True, stopPropagation = True })
            (JD.field "clientX" JD.float)
            (JD.field "clientY" JD.float)


event : menu -> UI.Attribute (Msg menu)
event menu =
    HE.custom "contextmenu" <|
        JD.map2 (\x y -> { message = Open x y menu, preventDefault = True, stopPropagation = True })
            (JD.field "clientX" JD.float)
            (JD.field "clientY" JD.float)



-- View


view : Model menu -> (Msg menu -> msg) -> (menu -> a -> Config msg menu) -> a -> UI msg
view model msgMap getConfig a =
    case model.openMenu of
        Just menu ->
            let
                config =
                    getConfig menu a

                entries =
                    List.foldr (renderEntry config) [] config.entries
            in
            col
                [ id "os-ctx-menu"
                , UI.style "top" <| (String.fromFloat model.posY ++ "px")
                , UI.style "left" <| (String.fromFloat model.posX ++ "px")
                , HE.onMouseEnter (msgMap OnCtxMenuEnter)
                , HE.onMouseLeave (msgMap OnCtxMenuLeave)
                ]
                entries

        Nothing ->
            UI.emptyEl


renderEntry : Config msg menu -> ConfigEntry msg -> List (UI msg) -> List (UI msg)
renderEntry config configEntry acc =
    case configEntry of
        SimpleItem item ->
            row
                [ cl "os-cm-simple-item-area"
                , case ( item.enabled, item.onClick ) of
                    ( True, Just msg ) ->
                        UI.onClick msg

                    ( _, _ ) ->
                        UI.emptyAttr
                , case ( item.enabled, item.onClick ) of
                    ( True, Just msg ) ->
                        HE.onMouseUp (config.mapper Close)

                    ( _, _ ) ->
                        UI.emptyAttr
                , if not item.enabled then
                    cl "os-cm-simple-item-disabled"

                  else
                    UI.emptyAttr
                ]
                [ text item.label ]
                :: acc

        Divisor ->
            row [ cl "os-cm-divisor-area" ] [ UI.hr ] :: acc



-- Subscriptions


isOpen : Model menu -> Bool
isOpen { openMenu } =
    Maybe.isJust openMenu


subscriptions : Model menu -> Sub (Msg menu)
subscriptions model =
    Sub.batch
        [ if isOpen model && not model.isHovered then
            -- TODO: Decide between onClick and onMouseDown. UX issues with other areas that are
            -- stopping propagation (close window; drag window; open CI selector)
            Browser.Events.onClick (JD.succeed Close)

          else
            Sub.none
        ]
