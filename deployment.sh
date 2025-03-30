#!/usr/bin/env bash

set -euo pipefail

APP_ENV=prod

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

function _main() {
    pushd "${PUBPST_PROJECT_DIRECTORY}" >/dev/null 2>&1

    _pubcst_print_context
    _pubpst_symfony_worker_stop
    _pubpst_sourecode_screen_stop
    _pubpst_composer_install
    _pubpst_wait_for_database
    _pubpst_symfony_cache_clear
    _pubpst_symfony_assets_install
    _pubpst_symfony_import_map_install
    _pubpst_symfony_migrations_migrate
    _pubpst_sourecode_screen_start

    popd >/dev/null 2>&1
}

_main
