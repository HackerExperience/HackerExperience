module UI.Model.FormFields exposing (..)

import Maybe.Extra as Maybe


type alias Field v =
    { value : v, error : Maybe String }


type alias TextField =
    Field String



-- Model > Field


baseField : v -> Field v
baseField value =
    { value = value
    , error = Nothing
    }


setValue : Field v -> v -> Field v
setValue field newValue =
    { field | value = newValue }


setError : Field v -> String -> Field v
setError field error =
    { field | error = Just error }


unsetError : Field v -> Field v
unsetError field =
    { field | error = Nothing }


hasError : Field v -> Bool
hasError field =
    Maybe.isJust field.error



-- Model > TextField


text : TextField
text =
    baseField ""


textWithValue : String -> TextField
textWithValue value =
    baseField value


isTextEmpty : TextField -> Bool
isTextEmpty textField =
    textField.value == ""
