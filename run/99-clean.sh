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
multipass delete ${NODES[@]}
multipass purge
multipass ls

set +x
echo ""

echo "removing temporary files (if exist):"
rm -v "${SCRIPTDIR%/*}/k3s.yaml"      2>/dev/null
rm -v "${SCRIPTDIR%/*}/k3s.yaml.back" 2>/dev/null
rm -v "$SCRIPTDIR/hosts"              2>/dev/null
rm -v "$SCRIPTDIR/etchosts"           2>/dev/null
rm -v "$SCRIPTDIR/etchosts.unix"      2>/dev/null

echo "done."
