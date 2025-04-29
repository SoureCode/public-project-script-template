#!/usr/bin/env bash

set -euo pipefail

PUBPST_CURRENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "${PUBPST_CURRENT_DIRECTORY}/_variables.sh"
source "${PUBPST_CURRENT_DIRECTORY}/_functions.sh"

#<editor-fold desc="options">
OPTIONS=$(getopt --options= --longoptions=help,no-schema-update,no-fixtures -- "$@")

if [ $? != 0 ]; then
    echo "Failed to parse options." >&2
    exit 1
fi

eval set -- "${OPTIONS}"

OPTION_NO_SCHEMA_UPDATE=false
OPTION_NO_FIXTURES=false

while [ $# -gt 0 ]; do
    case "${1}" in
    --no-schema-update)
        OPTION_NO_SCHEMA_UPDATE=true
        shift
        ;;
    --no-fixtures)
        OPTION_NO_FIXTURES=true
        shift
        ;;
    --help)
        echo "Usage: $0 [--help] [--no-schema-update] [--no-fixtures]" 1>&2
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
function _main() {
    pushd "${PUBPST_PROJECT_DIRECTORY}" >/dev/null 2>&1

    _pubcst_print_context

    _pubpst_composer_install
    _pubpst_check_requirements

    # stop
    _pubpst_symfony_worker_stop
    _pubpst_sourecode_screen_stop
    _pubpst_docker_compose_down
    _pubpst_symfony_server_stop

    _pubpst_docker_compose_up

    # database
    _pubpst_wait_for_database
    _pubpst_symfony_migrations_migrate
    _pubpst_symfony_schema_update "$OPTION_NO_SCHEMA_UPDATE"
    _pubpst_symfony_fixtures_load "$OPTION_NO_FIXTURES"

    # cache and assets
    _pubpst_symfony_cache_clear
    _pubpst_symfony_assets_install
    _pubpst_symfony_import_map_install

    # start
    _pubpst_sourecode_screen_start
    _pubpst_symfony_server_start

    popd >/dev/null 2>&1
}
#</editor-fold>

_main
