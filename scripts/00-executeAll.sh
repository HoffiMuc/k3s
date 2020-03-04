#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

finish() {
    set +x
}
trap finish EXIT

set -e
set -x

$SCRIPTDIR/02-setupVMs.sh
$SCRIPTDIR/03-deployK3s.sh
