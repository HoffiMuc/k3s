#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

finish() {
    errorcode=$?
    set +x
    return $errorcode
}
trap finish EXIT

set -ue
set -x

$SCRIPTDIR/02-setupVMs.sh
$SCRIPTDIR/03-deployK3s.sh
