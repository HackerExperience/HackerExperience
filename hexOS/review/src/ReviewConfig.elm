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
import NoRedundantConcat
import NoRedundantCons
import NoSimpleLetBody
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


config : List Rule
config =
    [ NoConfusingPrefixOperator.rule
    , NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
        -- We use `Debug.toString` at Main in order to enable the `elm-time-travel` debugger
        |> Rule.ignoreErrorsForFiles [ "src/Main.elm" ]
    , NoExposingEverything.rule
        |> Rule.ignoreErrorsForDirectories [ "tests", "src/UI", "src/Apps", "src/API" ]
        |> Rule.ignoreErrorsForFiles [ "src/UI.elm", "src/Utils.elm", "src/Effect.elm" ]
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
            ]
        -- Below ignored files are WIP and should eventually be fixed (either used or removed)
        |> Rule.ignoreErrorsForFiles [ "src/Common/Assets.elm" ]
    , NoUnused.Parameters.rule
        |> Rule.ignoreErrorsForDirectories [ "src/API/Lobby", "src/API/Game" ]
    , NoUnused.Patterns.rule
        |> Rule.ignoreErrorsForDirectories [ "src/OpenApi" ]
        -- WIP files; remove when no longer WIP
        |> Rule.ignoreErrorsForFiles [ "tests/Simulator.elm" ]
    , NoUnused.Variables.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , Simplify.rule Simplify.defaults
    , NoRedundantConcat.rule
    , NoRedundantCons.rule
    , NoLeftPizza.rule NoLeftPizza.Redundant
    , NoModuleOnExposedNames.rule
    , NoUnsafePorts.rule NoUnsafePorts.onlyIncomingPorts
    , NoUnusedPorts.rule
    , NoDuplicatePorts.rule
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
            , "src/Apps/Popups/ConfirmationDialog.elm"
            , "src/UI/Button.elm"
            , "src/API/Types.elm"
            ]
        -- Below files should always have this rule skipped
        |> Rule.ignoreErrorsForFiles []

    -- Useful for finding unused types but no.
    , NoUnused.CustomTypeConstructorArgs.rule
    ]
