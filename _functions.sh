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