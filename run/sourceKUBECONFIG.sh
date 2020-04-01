#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# defines NODES array
source "$SCRIPTDIR/00-setupVars.sh" silent

if [[ ! -f "${SCRIPTDIR%/*}/k3s.yaml" ]]; then
    echo "${SCRIPTDIR%/*}/k3s.yaml not found!"
fi

finish() {
    errorcode=$?
    set +x
    return $errorcode
}
trap finish EXIT

if [[ -z $1 ]]; then
    export KUBECONFIG=${SCRIPTDIR%/*}/k3s.yaml
    echo "export KUBECONFIG=${SCRIPTDIR%/*}/k3s.yaml"
else
    echo "unset KUBECONFIG ; cp \"${SCRIPTDIR%/*}/k3s.yaml\" ~/.kube/config"
    if [[ -f "$HOME/.kube/config" ]]; then mv "$HOME/.kube/config" "$HOME/.kube/config_$(date +%Y%m%d_%H%M%S)" ; fi
    unset KUBECONFIG ; cp "${SCRIPTDIR%/*}/k3s.yaml" ~/.kube/config
fi