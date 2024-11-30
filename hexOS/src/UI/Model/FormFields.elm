module UI.Model.FormFields exposing (..)


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



-- Model > TextField


text : TextField
text =
    baseField ""


textWithValue : String -> TextField
textWithValue value =
    baseField value
