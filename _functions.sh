#!/usr/bin/env bash
###############################################################################
# DO NOT MODIFY THIS FILE
#
# This file is maintained by the template.
# Any changes you make here will be automatically overwritten.
#
# If modifications are necessary, please update the template instead.
###############################################################################

set -euo pipefail

PUBPST_CURRENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "${PUBPST_CURRENT_DIRECTORY}/_variables.sh"

if [ -f "${PUBPST_SCRIPT_DIRECTORY}/public-common/_functions.sh" ]; then
    # this is the case for installation in a project
    # shellcheck source=../public-common/_functions.sh
    source "${PUBPST_SCRIPT_DIRECTORY}/public-common/_functions.sh"
elif [ -f "${PUBPST_CURRENT_DIRECTORY}/scripts/public-common/_functions.sh" ]; then
    # this is the case for installation in development of this template
    source "${PUBPST_CURRENT_DIRECTORY}/scripts/public-common/_functions.sh"
else
    echo "Missing public-common script-template."
    exit 1
fi

#<editor-fold desc="binary functions">
_PUBPST_CONSOLE_BINARY_CACHE=""
_PUBPST_HAS_CONSOLE=false
function _pubcst_console() {
    if [ "$_PUBCST_HAS_SYMFONY" = true ]; then
        _pubcst_symfony console "$@"
    else
        if [ -z "$_PUBPST_CONSOLE_BINARY_CACHE" ]; then
            _PUBPST_CONSOLE_BINARY_CACHE="${PUBPST_PROJECT_DIRECTORY}/bin/console"

            if [ ! -f "$_PUBPST_CONSOLE_BINARY_CACHE" ]; then
                echo "missing binary ${_PUBPST_CONSOLE_BINARY_CACHE}"
                exit 1
            fi

            _PUBPST_HAS_CONSOLE=true
        fi

        "$_PUBPST_CONSOLE_BINARY_CACHE" "$@"
    fi
}
#</editor-fold>

#<editor-fold desc="database functions">
function _pubpst_wait_for_database() {
    local ATTEMPTS_LEFT_TO_REACH_DATABASE=30
    local DATABASE_ERROR
    local EXIT_CODE

    echo "Waiting for database to be ready..."

    while [ $ATTEMPTS_LEFT_TO_REACH_DATABASE -gt 0 ]; do
        DATABASE_ERROR="$(_console dbal:run-sql -q "SELECT 1" 2>&1)"
        EXIT_CODE=$?

        if [ "${EXIT_CODE}" -eq 0 ]; then
            echo "The database is now ready and reachable"
            return 0
        elif [ "${EXIT_CODE}" -eq 255 ]; then
            echo "Unrecoverable error encountered:"
            echo "$DATABASE_ERROR"
            exit 1
        fi

        sleep 1
        ATTEMPTS_LEFT_TO_REACH_DATABASE=$((ATTEMPTS_LEFT_TO_REACH_DATABASE - 1))
        echo "Still waiting for the database... $ATTEMPTS_LEFT_TO_REACH_DATABASE attempts left."
    done

    echo "The database is not up or not reachable:"
    echo "$DATABASE_ERROR"
    exit 1
}
#</editor-fold>
