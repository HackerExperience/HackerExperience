module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import Docs.ReviewAtDocs
import NoConfusingPrefixOperator
import NoDebug.Log
import NoDebug.TodoOrToString
import NoDeprecated
import NoDuplicatePorts
import NoExposingEverything
import NoImportingEverything
import NoLeftPizza
import NoMissingTypeAnnotation
import NoMissingTypeAnnotationInLetIn
import NoMissingTypeExpose
import NoModuleOnExposedNames
import NoPrematureLetComputation
import NoPrimitiveTypeAlias
import NoRedundantConcat
import NoRedundantCons
import NoSimpleLetBody
import NoUnsafeDivision
import NoUnsafePorts
import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import NoUnusedPorts
import Review.Rule as Rule exposing (Rule)
import Simplify
import UseMemoizedLazyLambda


ignoreSdkFiles : Rule -> Rule
ignoreSdkFiles =
    Rule.ignoreErrorsForFiles
        [ "src/API/Lobby/Api.elm"
        , "src/API/Lobby/Json.elm"
        , "src/API/Game/Api.elm"
        , "src/API/Game/Types.elm"
        , "src/API/Game/Json.elm"
        , "src/API/Events/Types.elm"
        , "src/API/Events/Json.elm"
        , "src/API/Logs/Types.elm"
        , "src/API/Logs/Json.elm"
        , "src/API/Processes/Types.elm"
        , "src/API/Processes/Json.elm"
        ]


config : List Rule
config =
    [ NoConfusingPrefixOperator.rule
    , NoDebug.Log.rule
        -- We use `Debug.log` to display events that failed to parse. We need that until a more
        -- robust, in-game UI is built (akin to a DevTools app)
        |> Rule.ignoreErrorsForFiles [ "src/Main.elm" ]
    , NoDebug.TodoOrToString.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
        -- We use `Debug.toString` at Main in order to enable the `elm-time-travel` debugger
        |> Rule.ignoreErrorsForFiles [ "src/Main.elm" ]
    , NoExposingEverything.rule
        |> Rule.ignoreErrorsForDirectories [ "tests", "src/UI", "src/Apps", "src/API" ]
        |> Rule.ignoreErrorsForFiles
            [ "src/UI.elm"
            , "src/Utils.elm"
            , "src/Effect.elm"
            , "src/OS/CtxMenu/Menus.elm"
            ]
    , NoImportingEverything.rule [ "Test" ]
    , NoDeprecated.rule NoDeprecated.defaults
    , NoMissingTypeAnnotation.rule
        -- Because of `elm-time-travel` debugger, it's inconvenient to type the `main` function
        |> Rule.ignoreErrorsForFiles [ "src/Main.elm" ]
    , NoSimpleLetBody.rule
    , NoUnused.Dependencies.rule
    , NoUnused.Exports.rule
        |> Rule.ignoreErrorsForDirectories
            [ "tests"
            , "src/UI"
            , "src/OpenApi"
            , "src/API"
            , "src/Apps"
            ]
        |> Rule.ignoreErrorsForFiles
            [ "src/UI.elm"
            , "src/Utils.elm"
            , "src/Effect.elm"
            , "src/Game.elm"
            , "src/DevTools/ReviewBypass.elm"
            ]
        -- Below ignored files are WIP and should eventually be fixed (either used or removed)
        |> Rule.ignoreErrorsForFiles [ "src/Common/Assets.elm" ]
        |> Rule.ignoreErrorsForFiles [ "src/Game/Model/SoftwareType.elm" ]
    , NoUnused.Parameters.rule
        |> ignoreSdkFiles
    , NoUnused.Patterns.rule
        |> Rule.ignoreErrorsForDirectories [ "src/OpenApi" ]
        -- WIP files; remove when no longer WIP
        |> Rule.ignoreErrorsForFiles [ "tests/Simulator.elm" ]
    , NoUnused.Variables.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
        |> ignoreSdkFiles
    , Simplify.rule Simplify.defaults
        |> ignoreSdkFiles
    , NoRedundantConcat.rule
    , NoRedundantCons.rule
    , NoLeftPizza.rule NoLeftPizza.Redundant
    , NoModuleOnExposedNames.rule
    , NoUnsafePorts.rule NoUnsafePorts.any
    , NoUnusedPorts.rule
    , NoDuplicatePorts.rule
    , NoUnsafeDivision.rule
    , UseMemoizedLazyLambda.rule
        |> Rule.ignoreErrorsForFiles [ "src/UI.elm" ]
    , NoPrimitiveTypeAlias.rule
        -- For now I'm okay with AppID being a primitive type alias
        |> Rule.ignoreErrorsForFiles [ "src/OS/AppID.elm" ]
        -- We have some "Raw*ID" instances for comparable entries in Dict/Sets. That's fine, as long
        -- as "Raw*ID"s remain as an implementation detail and are never exposed by the API.
        -- The same comment applies to "RawNIP".
        |> Rule.ignoreErrorsForFiles
            [ "src/Game/Model/NIP.elm"
            , "src/Game/Model/LogID.elm"
            , "src/Game/Model/FileID.elm"
            , "src/Game/Model/InstallationID.elm"
            , "src/Game/Model/ProcessID.elm"
            , "src/Game/Model/TunnelID.elm"
            ]
        -- Below files are wrong and should eventually be fixed
        |> Rule.ignoreErrorsForFiles [ "src/WM.elm" ]
        -- Below files are outside my control
        |> Rule.ignoreErrorsForFiles
            [ "src/API/Game/Types.elm"
            , "src/API/Lobby/Types.elm"
            ]
    ]


{-| I deemed them to be not worth the trouble, at least for the time being.
-}
rulesThatAreRecommendedButIIgnoredThem : List Rule
rulesThatAreRecommendedButIIgnoredThem =
    [ NoMissingTypeAnnotationInLetIn.rule
    , NoMissingTypeExpose.rule

    -- I like the idea behind this one, but I can't enforce it. There is premature computation,
    -- "premature" computation and premature "computation".
    -- This rule is absolutely worth it for the first version (without quotes), but it's bad when:
    --
    -- * "premature" computation happens, that is, the computation will be used 90+% of the time.
    -- * premature "computation" happens, that is, the computation is extremely cheap.
    --
    -- For the two scenarios above, this rule is *not worth it* if it results in less readable code.
    --
    -- I should periodically run this rule manually and make sure there's no premature computation
    -- (without quotes) happening, but unfortunately that can't be automated.
    , NoPrematureLetComputation.rule

    -- I like this rule (and it actually caught one typeo (typo in type)) but it may be an
    -- inconvenience on WIP modules (especially at the early stages of the codebase). I tried using
    -- it by manually skipping WIP files but I think it will not be worth the trouble.
    , NoUnused.CustomTypeConstructors.rule []
        |> Rule.ignoreErrorsForDirectories [ "src/OpenApi" ]
        -- Below files are WIP.
        |> Rule.ignoreErrorsForFiles
            [ "src/Game.elm"
            , "src/Main.elm"
            , "src/Apps/Popups/DemoSingleton.elm"
            , "src/Apps/Popups/ConfirmationPrompt.elm"
            , "src/UI/Button.elm"
            , "src/API/Types.elm"
            ]
        -- Below files should always have this rule skipped
        |> Rule.ignoreErrorsForFiles []

    -- Useful for finding unused types but no.
    , NoUnused.CustomTypeConstructorArgs.rule
    ]
