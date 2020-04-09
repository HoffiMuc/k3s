#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

finish() {
    errorcode=$?
    set +x
    return $errorcode
}
trap finish EXIT

set -u

echo "testing image registry with curl:"
echo "to service directly (via :5000)"
echo "http:"
echo "curl -k http://registry.${MYCLUSTER_DOMAIN}:5000/v2/_catalog"
curl -k http://registry.${MYCLUSTER_DOMAIN}:5000/v2/_catalog
echo "https:"
echo "curl -k https://registry.${MYCLUSTER_DOMAIN}:5000/v2/_catalog"
curl -k https://registry.${MYCLUSTER_DOMAIN}:5000/v2/_catalog
REGISTRY_SVC_NODE_IP=$(kubectl -n ${REGISTRY_NAMESPACE} get service/docker-registry | tail -n +2 | awk '{print $4}')
echo "http:"
echo "curl -k http://${REGISTRY_SVC_NODE_IP}:5000/v2/_catalog"
curl -k http://${REGISTRY_SVC_NODE_IP}:5000/v2/_catalog
echo "https:"
echo "curl -k https://${REGISTRY_SVC_NODE_IP}:5000/v2/_catalog"
curl -k https://${REGISTRY_SVC_NODE_IP}:5000/v2/_catalog
echo
echo "via ingress"
echo "http:"
echo "curl -k http://registry.${MYCLUSTER_DOMAIN}/v2/_catalog"
curl -k http://registry.${MYCLUSTER_DOMAIN}/v2/_catalog
echo "https:"
echo "curl -k https://registry.${MYCLUSTER_DOMAIN}/v2/_catalog"
curl -k https://registry.${MYCLUSTER_DOMAIN}/v2/_catalog

