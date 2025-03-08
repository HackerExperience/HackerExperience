module OS.CtxMenu exposing
    ( Model
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
import UI exposing (UI, div, id)



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
            ( { model | openMenu = Just menu, posX = posX, posY = posY, isHovered = True }
            , Effect.none
            )

        Close ->
            ( { model | openMenu = Nothing }, Effect.none )

        OnCtxMenuEnter ->
            ( { model | isHovered = True }, Effect.none )

        OnCtxMenuLeave ->
            ( { model | isHovered = False }, Effect.none )

        NoOp ->
            ( model, Effect.none )



-- View


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


view : Model menu -> (Msg menu -> msg) -> (menu -> a -> UI msg) -> a -> UI msg
view model msgMap renderer a =
    case model.openMenu of
        Just menu ->
            div
                [ id "ctx-menu"
                , UI.style "top" <| (String.fromFloat model.posY ++ "px")
                , UI.style "left" <| (String.fromFloat model.posX ++ "px")
                , HE.onMouseEnter (msgMap OnCtxMenuEnter)
                , HE.onMouseLeave (msgMap OnCtxMenuLeave)
                ]
                [ renderer menu a ]

        Nothing ->
            UI.emptyEl



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
