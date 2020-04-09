#!/usr/bin/env bash

# roughly based on https://itnext.io/setup-a-private-registry-on-k3s-f30404f8e4d3

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPOROOTDIR=${SCRIPTDIR%/*}

# defines MYCLUSTER_DOMAIN
source "$SCRIPTDIR/00-setupVars.sh"

finish() {
    errorcode=$?
    set +x
    return $errorcode
}
trap finish EXIT

echo $0
echo ${0//?/=}
echo

set -ue
set -x

if [[ ${REGISTRY_NAMESPACE} != "kube-system" ]] && ! kubectl get namespace ${REGISTRY_NAMESPACE} > /dev/null 2>&1 ; then
    kubectl create namespace ${REGISTRY_NAMESPACE}
fi

kubectl -n ${REGISTRY_NAMESPACE} apply -f "${REPOROOTDIR}/resources/registry-deployment.yaml"
kubectl -n ${REGISTRY_NAMESPACE} apply -f "${REPOROOTDIR}/resources/registry-service.yaml"
kubectl -n ${REGISTRY_NAMESPACE} apply -f "${REPOROOTDIR}/resources/registry-ingress.yaml"
set +x


${SCRIPTDIR}/21-setupDnsmasq.sh

sleep 2
echo
echo "maybe you have to do some of the following also:"
echo "================================================"
echo "set 127.0.0.1 as your nameserver is using dnsmasq!!!"
echo ""
echo "sudo security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain ${CERT_FILENAME}"
echo " or on linux:"
echo "sudo mkdir -p /etc/docker/certs.d/${MYCLUSTER_DOMAIN}:5000"
echo "sudo cp ${CERT_FILENAME} /etc/docker/certs.d/${MYCLUSTER_DOMAIN}:5000/$(echo $CERT_FILENAME | sed -n -E 's#.*/(.*)\..*#\1#p').crt"
echo "and"
echo "restart docker service"
echo ""
