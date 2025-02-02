#!/usr/bin/env bash

# Why this file exists? Well, we use elm-program-test for thorough testing and we often need some
# modules to be changed slightly for them to be "mocked" via the "SimulatedEffects pattern".
# That's what this script does: it creates the "simulated counterpart", by copying the real
# modules and updating only what needs to be updated.
# `setup.sh` only needs to run once (unless you modified any of the files it copies, of course) and
# you can leave `elm-test --watch` running in the background without issues.

set -euo pipefail

if [ ! -f "elm.json" ]; then
    echo "Wrong dir; please run this script from hexOS root" && exit 1
fi

insert_import() {
    sed -i "0,/import/s//${1}\n&/" $2
}

add_SimulatedTask() {
    insert_import "import ProgramTest exposing (SimulatedTask)" $1
}

add_SimulatedEffectHttp() {
    insert_import "import SimulatedEffect.Http as Http" $1
}

add_SimulatedEffectHttpAsHttpSim() {
    insert_import "import SimulatedEffect.Http as HttpSim" $1
}

add_SimulatedEffectTask() {
    insert_import "import SimulatedEffect.Task as Task" $1
}

add_SimulatedCommon() {
    insert_import "import OpenApi.SimulatedCommon" $1
}

remove_moduleHttp() {
    sed -i '/import Http/d' $1
}

remove_moduleTask() {
    sed -i '/import Task/d' $1
}

remove_moduleOpenApiCommon() {
    sed -i '/import OpenApi.Common/d' $1
}

format() {
    elm-format --yes $1 > /dev/null
}

setup_simulated_spec() {
    SPEC_FILE=$1
    TARGET_FILE=$(echo $1 | sed 's/Api/SimulatedApi/')

    # Copy the file
    cp $SPEC_FILE $TARGET_FILE

    # Replace module name
    sed -i '1 s/\.Api/\.SimulatedApi/' $TARGET_FILE

    # Handle imports
    add_SimulatedTask $TARGET_FILE
    add_SimulatedEffectHttp $TARGET_FILE
    add_SimulatedCommon $TARGET_FILE
    remove_moduleHttp $TARGET_FILE
    remove_moduleOpenApiCommon $TARGET_FILE
    remove_moduleTask $TARGET_FILE

    # Replace Task.Task with SimulatedTask
    sed -i 's/Task\.Task/SimulatedTask/' $TARGET_FILE

    # Replace OpenApi.Common with OpenApi.SimulatedCommon
    sed -i 's/OpenApi\.Common/OpenApi\.SimulatedCommon/' $TARGET_FILE

    # Format file
    format $TARGET_FILE
}

setup_simulated_openapi_common() {
    SPEC_FILE="src/OpenApi/Common.elm"
    TARGET_FILE="src/OpenApi/SimulatedCommon.elm"

    # Copy the file
    cp $SPEC_FILE $TARGET_FILE

    # Replace module name
    sed -i 's/\.Common/\.SimulatedCommon/g' $TARGET_FILE

    # Handle imports
    add_SimulatedEffectHttpAsHttpSim $TARGET_FILE

    # Use HttpSim when calling expectStringResponse / stringResolver
    sed -i 's/Http\.expectStringResponse/HttpSim\.expectStringResponse/' $TARGET_FILE
    sed -i 's/Http\.stringResolver/HttpSim\.stringResolver/' $TARGET_FILE

    # Use HttpSim in the type
    sed -i 's/Http\.Expect/HttpSim\.Expect/' $TARGET_FILE
    sed -i 's/Http\.Resolver/HttpSim\.Resolver/' $TARGET_FILE

    # Format file
    format $TARGET_FILE
}

setup_simulated_utils() {
    SPEC_FILE="src/API/Utils.elm"
    TARGET_FILE="src/API/SimulatedUtils.elm"

    # Copy the file
    cp $SPEC_FILE $TARGET_FILE

    # Replace module name
    sed -i '1 s/\.Utils/\.SimulatedUtils/' $TARGET_FILE

    # Handle imports
    add_SimulatedTask $TARGET_FILE
    add_SimulatedEffectTask $TARGET_FILE
    add_SimulatedCommon $TARGET_FILE
    remove_moduleOpenApiCommon $TARGET_FILE
    remove_moduleTask $TARGET_FILE

    # Replace Task.Task with SimulatedTask
    sed -i 's/ Task / SimulatedTask /g' $TARGET_FILE

    # Replace OpenApi.Common with OpenApi.SimulatedCommon
    sed -i 's/OpenApi\.Common/OpenApi\.SimulatedCommon/' $TARGET_FILE

    # Format file
    format $TARGET_FILE
}

setup_simulated_api() {
    SPEC_FILE=$1
    API_NAME=$2
    SIMULATED_NAME=$3
    TARGET_FILE=$(echo $1 | sed "s/${API_NAME}/${SIMULATED_NAME}/")

    # Copy the file
    cp $SPEC_FILE $TARGET_FILE

    # Replace module name
    sed -i "1 s/${API_NAME}/${SIMULATED_NAME}/" $TARGET_FILE

    # Handle imports
    add_SimulatedTask $TARGET_FILE
    remove_moduleTask $TARGET_FILE

    # Replace spec module (e.g. API.Lobby.API -> API.Lobby.SimulatedApi)
    sed -i "s/import API.${API_NAME}.Api/import API.${API_NAME}.SimulatedApi/" $TARGET_FILE
    sed -i "s/import API.Utils/import API.SimulatedUtils/" $TARGET_FILE

    # Replace Task types in header
    sed -i 's/ Task / SimulatedTask /g' $TARGET_FILE

    # Format file
    format $TARGET_FILE
}

setup_simulated_openapi_common
setup_simulated_utils
setup_simulated_spec "src/API/Lobby/Api.elm"
setup_simulated_api "src/API/Lobby.elm" "Lobby" "SimulatedLobby"
