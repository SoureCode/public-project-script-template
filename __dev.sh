#!/usr/bin/env bash

set -euo pipefail

PUBPST_CURRENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

#<editor-fold desc="main">
pushd "${PUBPST_CURRENT_DIRECTORY}" >/dev/null 2>&1

# remove if already installed, to avoid orphaned files
if [ -d "scripts/public-common" ]; then
    rm -rf "scripts/public-common"
fi

git clone --depth 1 --branch master "git@github.com:SoureCode/public-common-script-template.git" "scripts/public-common"
rm -rf "scripts/public-common/.git"

popd >/dev/null 2>&1
#</editor-fold>
