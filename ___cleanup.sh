#!/usr/bin/env bash

set -euo pipefail

PUBCST_CURRENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PUBCST_IS_IN_GIT="$(git rev-parse --is-inside-work-tree >/dev/null 2>&1 && echo true || echo false)"

if git remote -v | grep -qe "-script-template" && [ "$PUBCST_IS_IN_GIT" = true ]; then
    PUBCST_GIT_ROOT_DIRECTORY="$(git rev-parse --show-toplevel 2>/dev/null || false)"

    if [ "$PUBCST_CURRENT_DIRECTORY" == "$PUBCST_GIT_ROOT_DIRECTORY" ]; then
        echo "Do not run this script inside a script-template repository."
        echo "It is only meant to be used inside a library or project to cleanup files which shouldn't be used."
        exit 1
    fi
fi

GIT_DIRECTORY="${PUBCST_CURRENT_DIRECTORY:?}/.git"
GIT_IGNORE_FILE="${PUBCST_CURRENT_DIRECTORY:?}/.gitignore"

if [ -d "${GIT_DIRECTORY:?}" ]; then
    echo "Removing ${GIT_DIRECTORY:?} directory"
    rm -rf "${GIT_DIRECTORY:?}"
else
    echo "No ${GIT_DIRECTORY:?} directory to remove."
fi

if [ -f "${GIT_IGNORE_FILE:?}" ]; then
    echo "Removing ${GIT_IGNORE_FILE:?} file"
    rm -f "${GIT_IGNORE_FILE:?}"
else
    echo "No ${GIT_IGNORE_FILE:?} file to remove."
fi

if [ -d "${PUBCST_CURRENT_DIRECTORY:?}" ]; then
    FILES="$(find "${PUBCST_CURRENT_DIRECTORY:?}" -maxdepth 1 -type f -name "__*")"

    if [ -n "${FILES:?}" ]; then
        echo "Removing the following files:"
        echo "${FILES:?}"
        find "${PUBCST_CURRENT_DIRECTORY:?}" -maxdepth 1 -type f -name "__*" -exec rm -f {} \;
    else
        echo "No files to remove."
    fi
fi
