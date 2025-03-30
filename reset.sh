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
pushd "${PUBPST_PROJECT_DIRECTORY}" >/dev/null 2>&1

_pubcst_print_context

if _pubcst_composer_has_package "symfony/messenger"; then
    _pubcst_console messenger:stop-workers --no-interaction --env="$APP_ENV"
fi

if _pubcst_composer_has_package "sourecode/screen-bundle"; then
    _pubcst_console screen:stop --no-interaction --env="$APP_ENV"
fi

if _pubcst_composer_has_package "doctrine/doctrine-bundle"; then
    _pubpst_wait_for_database

    _pubcst_console doctrine:database:drop --no-interaction --if-exists --force --env="$APP_ENV"
    _pubcst_console doctrine:database:create --no-interaction --if-not-exists --env="$APP_ENV"
fi

if _pubcst_composer_has_package "symfony/framework-bundle"; then
    _pubcst_console cache:clear --no-interaction --no-warmup --env="$APP_ENV"
    _pubcst_console cache:warmup --no-interaction --env="$APP_ENV"
    _pubcst_console assets:install --no-interaction --env="$APP_ENV"
fi

if _pubcst_composer_has_package "symfony/asset-mapper"; then
    _pubcst_console importmap:install --no-interaction --env="$APP_ENV"
fi

if _pubcst_composer_has_package "doctrine/doctrine-migrations-bundle"; then
    _pubcst_console doctrine:migrations:migrate --no-interaction --allow-no-migration --all-or-nothing --env="$APP_ENV"
fi

if _pubcst_composer_has_package "doctrine/doctrine-bundle" && ! "$OPTION_NO_SCHEMA_UPDATE"; then
    _pubcst_console doctrine:schema:update --dump-sql --no-interaction --env="$APP_ENV"
    _pubcst_console doctrine:schema:update --force --no-interaction --env="$APP_ENV"
fi

if _pubcst_composer_has_package "doctrine/doctrine-fixtures-bundle" && ! "$OPTION_NO_FIXTURES"; then
    _pubcst_console doctrine:fixtures:load --no-interaction --env="$APP_ENV"
fi

if _pubcst_composer_has_package "sourecode/screen-bundle"; then
    _pubcst_console screen:start --no-interaction --env="$APP_ENV"
fi

popd >/dev/null 2>&1
#</editor-fold>
