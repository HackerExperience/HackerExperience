module Game.Model.SoftwareType exposing
    ( SoftwareType(..)
    , typeFromString
    , typeToIcon
    , typeToName
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


typeToName : SoftwareType -> String
typeToName type_ =
    case type_ of
        SoftwareCracker ->
            "Cracker"

        SoftwareLogEditor ->
            "Log Editor"

        SoftwareInvalid _ ->
            "Invalid"


{-| NOTE: None of these icons are definitive. Just placeholders.
-}
typeToIcon : SoftwareType -> String
typeToIcon type_ =
    case type_ of
        SoftwareCracker ->
            "tools_power_drill"

        SoftwareLogEditor ->
            "edit_note"

        SoftwareInvalid _ ->
            "close"
