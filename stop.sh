#!/usr/bin/env bash

set -euo pipefail

PUBPST_CURRENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "${PUBPST_CURRENT_DIRECTORY}/_variables.sh"
source "${PUBPST_CURRENT_DIRECTORY}/_functions.sh"

#<editor-fold desc="options">
OPTIONS=$(getopt --options= --longoptions=help -- "$@")

if [ $? != 0 ]; then
    echo "Failed to parse options." >&2
    exit 1
fi

eval set -- "${OPTIONS}"

while [ $# -gt 0 ]; do
    case "${1}" in
    --help)
        echo "Usage: $0 [--help]" 1>&2
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

if _pubcst_composer_has_package "symfony/messenger"; then
    _pubcst_console messenger:stop-workers --no-interaction --env="$APP_ENV"
fi

if _pubcst_composer_has_package "sourecode/screen-bundle"; then
    _pubcst_console screen:stop --no-interaction --env="$APP_ENV"
fi

if [ -f compose.yaml ] || [ -f docker-compose.yaml ] || [ -f docker-compose.yml ] || [ -f compose.yml ]; then
    _pubcst_docker compose down --remove-orphans
fi

_pubcst_symfony server:stop

popd >/dev/null 2>&1
#</editor-fold>
