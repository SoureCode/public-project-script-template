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
                echo "missing binary ${_PUBPST_CONSOLE_BINARY_CACHE}" >&2
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
    if _pubcst_composer_has_package "doctrine/doctrine-bundle"; then
        local ATTEMPTS_LEFT_TO_REACH_DATABASE=30
        local DATABASE_ERROR
        local EXIT_CODE

        _pubpst_log --no-newline "Waiting for database to be ready"

        while [ $ATTEMPTS_LEFT_TO_REACH_DATABASE -gt 0 ]; do
            _pubcst_console dbal:run-sql -q "SELECT 1"
            if DATABASE_ERROR="$(_pubcst_console dbal:run-sql -q "SELECT 1" 2>&1)"; then
                _pubpst_log ""
                _pubpst_log "The database is now ready and reachable"
                return 0
            else
                EXIT_CODE=$?

                if [ "${EXIT_CODE}" -eq 255 ]; then
                    _pubpst_log ""
                    _pubpst_log "Unrecoverable error encountered:"
                    _pubpst_log "$(_pubpst_log_indent "$DATABASE_ERROR")"
                    exit 1
                fi
            fi

            sleep 1
            ATTEMPTS_LEFT_TO_REACH_DATABASE=$((ATTEMPTS_LEFT_TO_REACH_DATABASE - 1))
            _pubpst_log --no-newline "."
            _pubpst_log --log "$(_pubpst_log_indent "$DATABASE_ERROR")"
        done

        _pubpst_log ""

        _pubpst_log "The database is not up or not reachable:"
        _pubpst_log "$(_pubpst_log_indent "$DATABASE_ERROR")"
        exit 1
    fi
}
#</editor-fold>

#<editor-fold desc="log functions">
_PUBPST_LATEST_LOG_ENTRY_TIMESTAMP=""
function _pubpst_log_now() {
    date +%s%N
}
function _pubpst_log_now_formatted() {
    local NOW="${1:-}"
    local TIMESTAMP

    TIMESTAMP=${NOW:0:10}

    date -d @"$TIMESTAMP" "+%Y-%m-%d %H:%M:%S"
}
function _pubpst_log_delta() {
    local NOW="${1:-}"
    local DELTA
    local DELTA_SECONDS
    local MINUTES
    local SECONDS
    local MILLISECONDS

    if [ -z "$_PUBPST_LATEST_LOG_ENTRY_TIMESTAMP" ]; then
        echo "+00:00.000"
        return 0
    fi

    DELTA=$((NOW - _PUBPST_LATEST_LOG_ENTRY_TIMESTAMP))
    DELTA_SECONDS=$((DELTA / 1000000000))
    MILLISECONDS=$(((DELTA % 1000000000) / 1000000))

    MINUTES=$((DELTA_SECONDS / 60))
    SECONDS=$((DELTA_SECONDS % 60))

    printf "+%02d:%02d.%03d\n" "$MINUTES" "$SECONDS" "$MILLISECONDS"
}
function _pubpst_log_file_rotate() {
    local MAX_LOG_SIZE=1048576 # 1MB
    local MAX_LOG_FILES=5
    local LOG_FILE_SIZE

    LOG_FILE_SIZE=$(stat -c%s "$PUBPST_LOG_FILE" 2>/dev/null) || return 1

    if [ "$LOG_FILE_SIZE" -ge "$MAX_LOG_SIZE" ]; then
        local INDEX

        for ((INDEX = MAX_LOG_FILES - 1; INDEX >= 1; INDEX--)); do
            if [ -f "${PUBPST_LOG_FILE}.${INDEX}" ]; then
                mv "${PUBPST_LOG_FILE}.${INDEX}" "${PUBPST_LOG_FILE}.$((INDEX + 1))"
            fi
        done

        mv "$PUBPST_LOG_FILE" "${PUBPST_LOG_FILE}.1"
        touch "$PUBPST_LOG_FILE"
    fi
}

_PUBPST_WAS_LAST_LOG_ENTRY_NEWLINE=true
function _pubpst_log() {
    local NEWLINE=true
    local LOG_ONLY=false

    if [[ "${1:-}" == "--no-newline" ]]; then
        NEWLINE=false
        shift
    fi

    if [[ "${1:-}" == "--log" ]]; then
        LOG_ONLY=true
        shift
    fi

    local MESSAGE
    local SHOULD_ADD_TIMESTAMP=true

    MESSAGE="${1}"

    if [[ ("$NEWLINE" = true && "$_PUBPST_WAS_LAST_LOG_ENTRY_NEWLINE" = false) || ("$NEWLINE" = false && "$_PUBPST_WAS_LAST_LOG_ENTRY_NEWLINE" = false) ]]; then
        SHOULD_ADD_TIMESTAMP=false
    fi

    #echo "<-$NEWLINE-$PUBPST_WAS_LAST_LOG_ENTRY_NEWLINE->" >&2

    if [ "$SHOULD_ADD_TIMESTAMP" = true ]; then
        local NOW
        local NOW_FORMATTED
        local NOW_DELTA
        local TIMESTAMP_PREFIX

        NOW="$(_pubpst_log_now)"
        NOW_FORMATTED="$(_pubpst_log_now_formatted "$NOW")"
        NOW_DELTA="$(_pubpst_log_delta "$NOW")"
        TIMESTAMP_PREFIX="[${NOW_FORMATTED}][${NOW_DELTA}] "

        _PUBPST_LATEST_LOG_ENTRY_TIMESTAMP="$NOW"

        MESSAGE="$(_pubpst_log_prefix "${MESSAGE}" "$TIMESTAMP_PREFIX")"
    fi

    local ARGS=()

    if [ "$NEWLINE" = false ]; then
        ARGS+=("-n")
        if [ "$LOG_ONLY" = false ]; then
            _PUBPST_WAS_LAST_LOG_ENTRY_NEWLINE=false
        fi
    else
        if [ "$LOG_ONLY" = false ]; then
            _PUBPST_WAS_LAST_LOG_ENTRY_NEWLINE=true
        fi
    fi

    if [ "$LOG_ONLY" = true ]; then
        echo "${ARGS[@]}" "${MESSAGE}" >>"${PUBPST_LOG_FILE}"
    else
        echo "${ARGS[@]}" "${MESSAGE}" | tee -a "${PUBPST_LOG_FILE}"
    fi

    _pubpst_log_file_rotate
}
function _pubpst_log_indent() {
    local MESSAGE="${1}"
    local INDENT_WIDTH="${2:-2}"
    local SPACES

    SPACES=$(printf "%*s" "$INDENT_WIDTH" "")

    _pubpst_log_prefix "$MESSAGE" " > $SPACES"
}
function _pubpst_log_prefix() {
    local MESSAGE="${1}"
    local PREFIX="${2}"
    local LINE

    while IFS= read -r LINE; do
        echo "${PREFIX}${LINE}"
    done <<<"$MESSAGE"
}
#</editor-fold>

#<editor-fold desc="helper functions">
function _pubpst_execute() {
    local NAME="${1}"
    shift

    local PRINT_OUTPUT=false

    if [[ "${1:-}" == "--print-output" ]]; then
        PRINT_OUTPUT=true
        shift
    fi

    local RESULT

    _pubpst_log --no-newline "Executing ${NAME}"

    if RESULT="$("$@" 2>&1)"; then
        _pubpst_log " [OK]"

        if "$PRINT_OUTPUT"; then
            _pubpst_log "$(_pubpst_log_indent "$RESULT")"
        else
            _pubpst_log --log "$(_pubpst_log_indent "$RESULT")"
        fi
    else
        _pubpst_log " [ERROR]"
        _pubpst_log "$(_pubpst_log_indent "$RESULT")"
        exit 1
    fi
}
function _pubpst_docker_compose_up() {
    if [ -f compose.yaml ] || [ -f docker-compose.yaml ] || [ -f docker-compose.yml ] || [ -f compose.yml ]; then
        _pubpst_execute "compose up" _pubcst_docker compose up --detach --remove-orphans
    fi
}

function _pubpst_docker_compose_down() {
    if [ -f compose.yaml ] || [ -f docker-compose.yaml ] || [ -f docker-compose.yml ] || [ -f compose.yml ]; then
        _pubpst_execute "compose down" _pubcst_docker compose down --remove-orphans
    fi
}

function _pubpst_composer_install() {
    local ARGS=()

    ARGS+=("--no-interaction")

    if _pubcst_is_prod; then
        ARGS+=("--no-dev" "--optimize-autoloader")
    fi

    _pubpst_execute "composer install" _pubcst_composer install "${ARGS[@]}"
}

function _pubpst_symfony_cache_clear() {
    if _pubcst_composer_has_package "symfony/framework-bundle"; then
        _pubpst_execute "cache clear" _pubcst_console cache:clear --no-interaction --no-warmup --env="$APP_ENV"
        _pubpst_execute "cache warmup" _pubcst_console cache:warmup --no-interaction --env="$APP_ENV"
    fi
}

function _pubpst_symfony_assets_install() {
    if _pubcst_composer_has_package "symfony/framework-bundle"; then
        _pubpst_execute "assets install" _pubcst_console assets:install --no-interaction --env="$APP_ENV"
    fi
}

function _pubpst_symfony_import_map_install() {
    if _pubcst_composer_has_package "symfony/asset-mapper"; then
        _pubpst_execute "import-map install" _pubcst_console importmap:install --no-interaction --env="$APP_ENV"

        if _pubcst_is_prod; then
            _pubpst_execute "asset-map compile" _pubcst_console asset-map:compile --no-interaction --env="$APP_ENV"
        fi
    fi
}

function _pubpst_symfony_migrations_migrate() {
    if _pubcst_composer_has_package "doctrine/doctrine-migrations-bundle"; then
        _pubpst_execute "migrations migrate" _pubcst_console doctrine:migrations:migrate --no-interaction --allow-no-migration --all-or-nothing --env="$APP_ENV"
    fi
}

function _pubpst_symfony_schema_update() {
    local OPTION_NO_SCHEMA_UPDATE="${1:-false}"

    if _pubcst_composer_has_package "doctrine/doctrine-bundle" && ! "$OPTION_NO_SCHEMA_UPDATE"; then
        _pubpst_execute "schema dump" --print-output _pubcst_console doctrine:schema:update --dump-sql --no-interaction --env="$APP_ENV"
        _pubpst_execute "schema update" _pubcst_console doctrine:schema:update --force --no-interaction --env="$APP_ENV"
    fi
}

function _pubpst_symfony_fixtures_load() {
    local OPTION_NO_FIXTURES="${1:-false}"

    if _pubcst_composer_has_package "doctrine/doctrine-fixtures-bundle" && ! "$OPTION_NO_FIXTURES"; then
        _pubpst_execute "fixtures load" _pubcst_console doctrine:fixtures:load --no-interaction --env="$APP_ENV"
    fi
}

function _pubpst_sourecode_screen_start() {
    if _pubcst_composer_has_package "sourecode/screen-bundle"; then
        _pubpst_execute "screen start" _pubcst_console screen:start --no-interaction --env="$APP_ENV"
    fi
}

function _pubpst_sourecode_screen_stop() {
    if _pubcst_composer_has_package "sourecode/screen-bundle"; then
        _pubpst_execute "screen stop" _pubcst_console screen:stop --no-interaction --env="$APP_ENV"
    fi
}

function _pubpst_symfony_worker_stop() {
    if _pubcst_composer_has_package "symfony/messenger"; then
        _pubpst_execute "worker stop" _pubcst_console messenger:stop-workers --no-interaction --env="$APP_ENV"
    fi
}

function _pubpst_symfony_server_start() {
    _pubpst_execute "server start" _pubcst_symfony serve --daemon
}

function _pubpst_symfony_server_stop() {
    _pubpst_execute "server stop" _pubcst_symfony server:stop
}

function _pubpst_symfony_database_drop() {
    if _pubcst_composer_has_package "doctrine/doctrine-bundle"; then
        _pubpst_wait_for_database

        _pubpst_execute "database drop" _pubcst_console doctrine:database:drop --no-interaction --if-exists --force --env="$APP_ENV"
        _pubpst_execute "database create" _pubcst_console doctrine:database:create --no-interaction --if-not-exists --env="$APP_ENV"
    fi
}
#</editor-fold>
