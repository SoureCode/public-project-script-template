#!/usr/bin/env bash

set -euo pipefail

PUBPST_CURRENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "${PUBPST_CURRENT_DIRECTORY}/_variables.sh"
source "${PUBPST_CURRENT_DIRECTORY}/_functions.sh"

function _main(){
    pushd "${PUBPST_PROJECT_DIRECTORY}" >/dev/null 2>&1

    # script-template dependencies
    _pubcst_git_update_template "master" "git@github.com:SoureCode/public-common-script-template.git" "scripts/public-common"

    # the actual script-template
    _pubcst_git_update_template "master" "git@github.com:SoureCode/public-project-script-template.git" "scripts/public-project"

    popd >/dev/null 2>&1
}

_main
