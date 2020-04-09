#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

finish() {
    errorcode=$?
    set +x
    return $errorcode
}
trap finish EXIT

set -x

time ${SCRIPTDIR}/44-testRegistry.sh
