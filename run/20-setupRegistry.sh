#!/usr/bin/env bash

# roughly based on https://itnext.io/setup-a-private-registry-on-k3s-f30404f8e4d3

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPOROOTDIR=${SCRIPTDIR%/*}

finish() {
    errorcode=$?
    set +x
    return $errorcode
}
trap finish EXIT

set -ue
set -x

# for k3s cert hostname CN = fqdn (or all node names)
certFileBasename="${HOME}/.ssh/registry"
if [[ $# > 0 ]]; then
    certFileBasename="${1%*.*}"
    error=1 # False
    if [[ ! -f "${certFileBasename}.crt" ]]; then error=1 ; >&2 echo "${certFileBasename}.crt not found!" ; fi
    if [[ ! -f "${certFileBasename}.key" ]]; then error=1 ; >&2 echo "${certFileBasename}.key not found!" ; fi
    if [[ $error ]]; then "please use absolute path or relative path from $REPOROOTDIR" ; exit 2 ; fi
fi

kubectl -n kube-system create secret tls registry-ingress-tls --cert="${certFileBasename}.crt" --key="${certFileBasename}.key"

kubectl apply -f "${REPOROOTDIR}/resources/registryHelm.yaml"
