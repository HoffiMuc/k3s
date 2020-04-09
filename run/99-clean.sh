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

set -u
set -x
multipass delete ${NODES[@]}
multipass purge
multipass ls

set +x
echo ""
echo "removing /etc/hosts entries ..."
sudo sed -E -i "" '/^192\.168\.64\..* node[0-9]/d' /etc/hosts # delete lines matching
sudo sed -E -i "" "\#^===== $SCRIPTDIR#d" /etc/hosts # delete lines matching
sudo sed -e :a -i "" -e  '/^\n*$/{$d;N;};/\n$/ba' /etc/hosts # delete trailing empty lines
sudo echo "" | sudo tee -a  /etc/hosts # add empty line to end

echo "removing temporary files (if exist):"
rm -v "${SCRIPTDIR%/*}/k3s.yaml"      2>/dev/null
rm -v "${SCRIPTDIR%/*}/k3s.yaml.back" 2>/dev/null
rm -v "$SCRIPTDIR/hosts"              2>/dev/null
rm -v "$SCRIPTDIR/etchosts"           2>/dev/null
rm -v "$SCRIPTDIR/etchosts.unix"      2>/dev/null

echo "done."
