module Game.Model.SoftwareType exposing
    ( SoftwareType(..)
    , typeFromString
    , typeToString
    )


type SoftwareType
    = SoftwareCracker
    | SoftwareLogEditor
    | SoftwareInvalid String


typeToString : SoftwareType -> String
typeToString type_ =
    case type_ of
        SoftwareCracker ->
            "cracker"

        SoftwareLogEditor ->
            "log_editor"

        SoftwareInvalid str ->
            "invalid:" ++ str


typeFromString : String -> SoftwareType
typeFromString rawType =
    case rawType of
        "cracker" ->
            SoftwareCracker

        "log_editor" ->
            SoftwareLogEditor

        _ ->
            SoftwareInvalid rawType
