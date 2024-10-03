#!/usr/bin/env bash

set -euo pipefail

if [ ! -f "elm.json" ]; then
    echo "Wrong dir; please run this script from hexOS root" && exit 1
fi

./node_modules/.bin/elm-review --watch
