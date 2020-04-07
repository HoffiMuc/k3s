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

set -ue
set -x

# for k3s cert hostname CN = fqdn (or all node names)
certFileBasename="${HOME}/.ssh/${MYCLUSTER_DOMAIN//./_}"
if [[ $# > 0 ]]; then
    certFileBasename="${1%*.*}"
    error=1 # False
    if [[ ! -f "${certFileBasename}.crt" ]]; then error=1 ; >&2 echo "${certFileBasename}.crt not found!" ; fi
    if [[ ! -f "${certFileBasename}.key" ]]; then error=1 ; >&2 echo "${certFileBasename}.key not found!" ; fi
    if [[ $error ]]; then "please use absolute path or a path relative from $REPOROOTDIR" ; exit 2 ; fi
fi

if kubectl -n kube-system get secret registry-ingress-tls 2>&1 >/dev/null ; then
    kubectl -n kube-system delete secret registry-ingress-tls
fi
kubectl -n kube-system create secret tls registry-ingress-tls --cert="${certFileBasename}.crt" --key="${certFileBasename}.key"

kubectl apply -f "${REPOROOTDIR}/resources/registry-deployment.yaml"
kubectl apply -f "${REPOROOTDIR}/resources/registry-service.yaml"
echo "!!! no ingress resources/registry-ingress.yaml deployed as not needed here!!!"
#kubectl apply -f "${REPOROOTDIR}/resources/registry-ingress.yaml"
set +x

if [[ -e /usr/local/etc/dnsmasq.conf ]]; then
    for i in {1..10}; do
        REGISTRY_SVC_NODE_IP=$(kubectl -n kube-system get service/image-registry | tail -n +2 | awk '{print $4}')
        if [[ "${REGISTRY_SVC_NODE_IP}" =~ [0-9.]+ ]]; then
            break
        fi
        sleep 0.3
    done
    OLD_REGISTRY_SVC_NODE_IP=$(sed -n -E "s#^address=/registry.${MYCLUSTER_DOMAIN}/([0-9.]*).*#\1#p" /usr/local/etc/dnsmasq.conf)
    echo "service/image-registry running on EXTERNAL-IP:   ${REGISTRY_SVC_NODE_IP}"
    echo "old dnsmasq registry service ip: ${OLD_REGISTRY_SVC_NODE_IP}"
    echo "new dnsmasq registry service ip: ${REGISTRY_SVC_NODE_IP}"
    if [[ ! "${OLD_REGISTRY_SVC_NODE_IP}" = "${REGISTRY_SVC_NODE_IP}" ]]; then
        set -x
        sed -E -i .bak "s#^address=/registry.${MYCLUSTER_DOMAIN}/.*#address=/registry.${MYCLUSTER_DOMAIN}/${REGISTRY_SVC_NODE_IP}#" /usr/local/etc/dnsmasq.conf
        sudo brew services restart dnsmasq
        set +x
        echo
    fi
fi

echo
echo "maybe you have to do some of the following also:"
echo "================================================"
echo "sudo security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain ~/.ssh/${certFileBasename}.crt"
echo "restart docker service"
echo ""
echo "testing image registry with curl:"
echo "curl -k https://registry.${MYCLUSTER_DOMAIN}:443/v2/_catalog"
curl -k https://registry.${MYCLUSTER_DOMAIN}:443/v2/_catalog # has to be 443 for docker push ending up with TLS at registry container