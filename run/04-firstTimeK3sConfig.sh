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

echo $0
echo ${0//?/=}
echo

set -ue
#set -x

NAMESPACES=( "registry-ns" )
for ns in "${NAMESPACES[@]}"; do
if [[ ${ns} != "kube-system" ]] && ! kubectl get namespace ${ns} > /dev/null 2>&1 ; then
    kubectl create namespace ${ns}
fi
done

sudo kubectl -n ${REGISTRY_NAMESPACE} create secret tls docker-registry-tls \
   --cert="${CERT_FILENAME}" --key="${CERT_KEY_FILENAME}"

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

echo "don't forget to set nameserver to local dnsmasq 127.0.0.1 !!!"