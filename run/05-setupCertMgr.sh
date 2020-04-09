#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPOROOTDIR=${SCRIPTDIR%/*}

# defines NODES array
source "$SCRIPTDIR/00-setupVars.sh"

finish() {
    errorcode=$?
    if [[ ${errorcode} -ne 0 ]]; then echo "... is nameserver pointing to ${MYCLUSTER_DOMAIN}? (dnsmasq?)" ; fi
    set +x
    return $errorcode
}
trap finish EXIT

echo $0
echo ${0//?/=}
echo

set -ue
#set -x

echo
echo "deploying cert-manager ..."
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.14.1/cert-manager.yaml
#echo
#echo "generating issuer and self-signed certificate:"
#echo kubectl apply -f "${REPOROOTDIR}/resources/certMgr-selfsigned.yaml"
#kubectl apply -f "${REPOROOTDIR}/resources/certMgr-selfsigned.yaml"
#echo
#echo "list issuers:"
#echo kubectl get issuers -n cert-manager
#kubectl get issuers -n cert-manager
#echo
#echo "list certificates:"
#echo kubectl get certificate -n cert-manager
#kubectl get certificate -n cert-manager
#echo
#echo "describe certificate 'selfsigned-cert':"
#echo kubectl describe certificate selfsigned-cert -n cert-manager
#kubectl describe certificate selfsigned-cert -n cert-manager