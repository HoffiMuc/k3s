#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# defines NODES array
source "$SCRIPTDIR/00-setupVars.sh"

finish() {
    errorcode=$?
    set +x
    if [[ -f "${SCRIPTDIR%/*}/k3s.yaml" ]]; then
        echo ""
        echo "export KUBECONFIG=${SCRIPTDIR%/*}/k3s.yaml"
    fi
    return $errorcode
}
trap finish EXIT

set -ue
set -x

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

