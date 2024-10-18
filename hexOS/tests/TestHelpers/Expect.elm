module TestHelpers.Expect exposing (..)

import Dict exposing (Dict)
import Dict.Extra as Dict
import Effect exposing (Effect)
import Expect as E
import Maybe.Extra as Maybe
import TestHelpers.Utils as TU exposing (str)


type alias Expectation =
    E.Expectation



-- Utils


batch : List Expectation -> Expectation
batch expectations =
    E.all (List.map always expectations) ()



-- Default expectations


equal : a -> a -> Expectation
equal =
    E.equal


notEqual : a -> a -> Expectation
notEqual =
    E.notEqual



-- Basic expectations with improved "ergonomics"


true : Bool -> Expectation
true value =
    E.equal value True


false : Bool -> Expectation
false value =
    E.equal value False


just : Maybe a -> Expectation
just value =
    true <| Maybe.isJust value


nothing : Maybe a -> Expectation
nothing value =
    E.equal value Nothing


emptyDict : Dict c a -> Expectation
emptyDict dict =
    E.equal Dict.empty dict


dictHasKey : Dict comparable a -> comparable -> Expectation
dictHasKey dict expectedKey =
    if Dict.any (\key _ -> key == expectedKey) dict then
        E.pass

    else
        E.fail <| "dictHasKey: key " ++ str expectedKey ++ " not found in " ++ str dict


notDictHasKey : Dict comparable a -> comparable -> Expectation
notDictHasKey dict forbiddenKey =
    if Dict.any (\key _ -> key == forbiddenKey) dict then
        E.fail <| "notDictHasKey: key " ++ str forbiddenKey ++ " found in " ++ str dict

    else
        E.pass



-- Effect expectations


effectMsgToCmd : Effect msg -> msg -> Expectation
effectMsgToCmd effect expectedMsg =
    case effect of
        Effect.MsgToCmd _ msg ->
            E.equal msg expectedMsg

        _ ->
            E.equal effect (Effect.MsgToCmd 0 expectedMsg)


effectNone : Effect msg -> Expectation
effectNone effect =
    case effect of
        Effect.None ->
            E.pass

        -- TODO: handle batch with only Nones in it
        _ ->
            E.equal effect Effect.None
