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
        echo "Usage: $0 [--help] [--no-schema-update]" 1>&2
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

# stop workers
if _pubcst_composer_has_package "symfony/messenger"; then
    _pubcst_console messenger:stop-workers --no-interaction
fi

# stop screens
if _pubcst_composer_has_package "sourecode/screen-bundle"; then
    _pubcst_console screen:stop --no-interaction
fi

# wait for database
if _pubcst_composer_has_package "doctrine/doctrine-bundle"; then
    _pubpst_wait_for_database

    # database drop
    _pubcst_console doctrine:database:drop --no-interaction --if-exists --force
    # database create
    _pubcst_console doctrine:database:create --no-interaction --if-not-exists
fi

if _pubcst_composer_has_package "symfony/framework-bundle"; then
    # cache clear
    _pubcst_console cache:clear --no-interaction --no-warmup
    # cache warmup
    _pubcst_console cache:warmup --no-interaction
    # assets install
    _pubcst_console assets:install --no-interaction
fi

if _pubcst_composer_has_package "symfony/asset-mapper"; then
    # importmap install
    _pubcst_console importmap:install --no-interaction
fi

if _pubcst_composer_has_package "doctrine/doctrine-migrations-bundle"; then
    # migrations
    _pubcst_console doctrine:migrations:migrate --allow-no-migration --all-or-nothing --no-interaction
fi

if _pubcst_composer_has_package "doctrine/doctrine-bundle" && ! "$OPTION_NO_SCHEMA_UPDATE"; then
    # schema update
    _pubcst_console doctrine:schema:update --dump-sql --force --no-interaction
fi

if _pubcst_composer_has_package "doctrine/doctrine-fixtures-bundle" && ! "$OPTION_NO_FIXTURES"; then
    # fixtures
    _pubcst_console doctrine:fixtures:load --no-interaction
fi

if _pubcst_composer_has_package "sourecode/screen-bundle"; then
    _pubcst_console screen:start --no-interaction
fi

popd >/dev/null 2>&1
#</editor-fold>
