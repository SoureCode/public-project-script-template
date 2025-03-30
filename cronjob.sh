#!/usr/bin/env bash

set -euo pipefail

PUBPST_CURRENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "${PUBPST_CURRENT_DIRECTORY}/_variables.sh"
source "${PUBPST_CURRENT_DIRECTORY}/_functions.sh"

#<editor-fold desc="options">
OPTIONS=$(getopt --options= --longoptions=help,interval:n -- "$@")

if [ $? != 0 ]; then
    echo "Failed to parse options." >&2
    exit 1
fi

eval set -- "${OPTIONS}"

INTERVAL=60

while [ $# -gt 0 ]; do
    case "${1}" in
    --interval)
        if ! [[ "${2}" =~ ^[0-9]+$ ]]; then
            echo "$0: error - invalid interval value $2" 1>&2
            exit 1
        fi

        INTERVAL="${2}"
        shift 2
        ;;
    --help)
        echo "Usage: $0 [--help] [--interval <seconds>]" 1>&2
        exit 0
        ;;
    --)
        shift
        break
        ;;
    -*)
        echo "$0: error - unrecognized option $1" 1>&2
        exit 1
        ;;
    *) break ;;
    esac
done
#</editor-fold>

#<editor-fold desc="main">
pushd "${PUBPST_PROJECT_DIRECTORY}" >/dev/null 2>&1

_pubcst_print_context

while true; do
    if _pubcst_composer_has_package "sourecode/screen-bundle"; then
        _pubcst_console screen:start --no-interaction --env="$APP_ENV"
    fi

    sleep "${INTERVAL}"
done

popd >/dev/null 2>&1
#</editor-fold>
