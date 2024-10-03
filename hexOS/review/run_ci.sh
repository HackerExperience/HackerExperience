#!/usr/bin/env bash

set -euo pipefail

if [ ! -f "elm.json" ]; then
    echo "Wrong dir; please run this script from hexOS root" && exit 1
fi

if [ -z "${CI:-}" ]; then
    echo "This command is only to be used under CI" && exit 1
fi

# Replace all unused variables with double underscores with a single underscore
# Example: appMsg__ gets replaced with _
find src/ -type f -name "*.elm" | xargs -I {} sed -Ei 's/[a-z][a-zA-Z0-9_]*__/_/g' {}

./node_modules/.bin/elm-review
