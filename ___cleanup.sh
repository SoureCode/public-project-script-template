#!/usr/bin/env bash

set -euo pipefail

PUBPST_CURRENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PUBPST_GIT_ROOT_DIRECTORY="$(git rev-parse --show-toplevel)"

if git remote -v | grep -qe "-script-template" && [ "${PUBPST_CURRENT_DIRECTORY:?}" == "${PUBPST_GIT_ROOT_DIRECTORY:?}" ]; then
    echo "Do not run this script inside a script-template repository."
    echo "It is only meant to be used inside a library or project to cleanup files which shouldn't be used."
    exit 1
fi

GIT_DIRECTORY="${PUBPST_CURRENT_DIRECTORY:?}/.git"
GIT_IGNORE_FILE="${PUBPST_CURRENT_DIRECTORY:?}/.gitignore"

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

if [ -d "${PUBPST_CURRENT_DIRECTORY:?}" ]; then
    FILES="$(find "${PUBPST_CURRENT_DIRECTORY:?}" -maxdepth 1 -type f -name "__*")"

    if [ -n "${FILES:?}" ]; then
        echo "Removing the following files:"
        echo "${FILES:?}"
        find "${PUBPST_CURRENT_DIRECTORY:?}" -maxdepth 1 -type f -name "__*" -exec rm -f {} \;
    else
        echo "No files to remove."
    fi
fi
