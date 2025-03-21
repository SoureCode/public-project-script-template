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
PUBPST_PROJECT_DIRECTORY="$(dirname "$(dirname "${PUBPST_CURRENT_DIRECTORY}")")"
PUBPST_SCRIPT_DIRECTORY="${PUBPST_PROJECT_DIRECTORY}/scripts"

if [ -f "${PUBPST_SCRIPT_DIRECTORY}/public-common/_variables.sh" ]; then
    # this is the case for installation in a project
    # shellcheck source=../public-common/_variables.sh
    source "${PUBPST_SCRIPT_DIRECTORY}/public-common/_variables.sh"
elif [ -f "${PUBPST_CURRENT_DIRECTORY}/scripts/public-common/_variables.sh" ]; then
    # this is the case for installation in development of this template
    source "${PUBPST_CURRENT_DIRECTORY}/scripts/public-common/_variables.sh"
else
    echo "Missing public-common script-template."
    exit 1
fi
