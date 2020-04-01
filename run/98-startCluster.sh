#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# defines NODES array
source "$SCRIPTDIR/00-setupVars.sh"

finish() {
    errorcode=$?
    set +x
    return $errorcode
}
trap finish EXIT

set -ue
set -x
# for i in {0..3}; do multipass start node$i & done
multipass start ${NODES[@]}

echo "done."
