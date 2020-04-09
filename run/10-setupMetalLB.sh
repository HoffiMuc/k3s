#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPOROOTDIR=${SCRIPTDIR%/*}

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

metalLBVersion='v0.9.3'

kubectl get svc -A | grep -E 'traefik[^-]' | awk '{print "traefik EXTERNAL-IP: " $5}'

kubectl apply -f https://raw.githubusercontent.com/google/metallb/${metalLBVersion}/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/google/metallb/${metalLBVersion}/manifests/metallb.yaml
# On first install only
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

kubectl apply -f "${REPOROOTDIR}/resources/metal-lb-layer2-config.yaml"

kubectl get svc -A
kubectl get svc -A | grep -E 'traefik[^-]' | awk '{print "traefik EXTERNAL-IP: " $5}'


echo
${SCRIPTDIR}/21-setupDnsmasq.sh traefik-ingress