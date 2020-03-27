#!/usr/bin/env bash

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
kubectl apply -f "${REPOROOTDIR}/whoami-deployment.yaml"
kubectl apply -f "${REPOROOTDIR}/whoami-service.yaml"
kubectl apply -f "${REPOROOTDIR}/whoami-ingress.yaml"
kubectl apply -f "${REPOROOTDIR}/whoareyou-service.yaml"
