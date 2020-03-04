#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# defines NODES array
source "$SCRIPTDIR/01-setupVars.sh"

finish() {
    set +x
}
trap finish EXIT

set -e
set -x

multipass delete ${NODES[@]}
multipass purge
multipass ls

rm "$SCRIPTDIR/hosts"
rm "$SCRIPTDIR/etchosts"
rm "$SCRIPTDIR/etchosts.unix"
