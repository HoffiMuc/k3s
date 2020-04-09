#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# defines NODES array
source "$SCRIPTDIR/00-setupVars.sh"

finish() {
    errorcode=$?
    set +x
    if [[ -f "${SCRIPTDIR%/*}/k3s.yaml" ]]; then
        echo ""
        echo "set kube context like:"
        echo "source run/sourceKUBECONFIG.sh"
        echo "or"
        echo "export KUBECONFIG=${SCRIPTDIR%/*}/k3s.yaml"
        echo "or"
        echo "unset KUBECONFIG ; cp \"${SCRIPTDIR%/*}/k3s.yaml\" ~/.kube/config"
        mv ~/.kube/config ~/.kube/config-$(date +%Y%m%d_%H%M%S)
        cp ${SCRIPTDIR%/*}/k3s.yaml ~/.kube/config
    fi
    return $errorcode
}
trap finish EXIT

LOCALK3SEXE="download"
if [ "$1" = "local" ] && [[ -e ${SCRIPTDIR}/k3sLocalScript/k3s ]]; then
    LOCALK3SEXE="local"
fi

echo $0
echo ${0//?/=}
echo

set -ue
set -x

if [[ $(ps -e | grep dnsmasq | wc -l) -gt 1 ]]; then echo "CAREFULL dnsmasq is running!!!" ; fi

# Deploy k3s master on node0
echo ""
if [ ${LOCALK3SEXE} = "local" ]; then
    multipass transfer ${SCRIPTDIR}/k3sLocalScript/k3s ${NODES[0]}:/tmp/
    multipass exec "${NODES[0]}" -- sudo mv /tmp/k3s /usr/local/bin/
    multipass exec "${NODES[0]}" -- sudo /bin/chmod 755 /usr/local/bin/k3s
fi
multipass exec "${NODES[0]}" -- /bin/bash -c "curl -sfL -C - https://get.k3s.io | sh -"
# Get the IP of the master node
K3S_NODEIP_MASTER="https://$(multipass info "${NODES[0]}" | grep "IPv4" | awk -F' ' '{print $2}'):6443"
# Get the TOKEN from the master node
K3S_TOKEN="$(multipass exec "${NODES[0]}" -- /bin/bash -c "sudo cat /var/lib/rancher/k3s/server/node-token")"
# Deploy k3s on the worker nodes (all but the first in NODES array)
for (( i=1; i<${#NODES[@]}; i++ )); do
    echo ""
    if [ ${LOCALK3SEXE} = "local" ]; then
        multipass transfer ${SCRIPTDIR}/k3sLocalScript/k3s ${NODES[$i]}:/tmp/
        multipass exec "${NODES[$i]}" -- sudo mv /tmp/k3s /usr/local/bin/
        multipass exec "${NODES[$i]}" -- sudo /bin/chmod 755 /usr/local/bin/k3s
    fi
    multipass exec "${NODES[$i]}" -- /bin/bash -c "curl -sfL -C - https://get.k3s.io | K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} sh -"
done
sleep 5

echo "############################################################################"
# multipass exec node1 -- bash -c "sudo kubectl get nodes"
multipass exec "${NODES[0]}" -- bash -c 'sudo cat /etc/rancher/k3s/k3s.yaml' > "${SCRIPTDIR%/*}/k3s.yaml"
sed -i'.back' -e "s/127.0.0.1/${NODES[0]}/g" "${SCRIPTDIR%/*}/k3s.yaml"
export KUBECONFIG="${SCRIPTDIR%/*}/k3s.yaml"
kubectl taint node "${NODES[0]}" --overwrite node-role.kubernetes.io/master=effect:NoSchedule
for (( i=1; i<${#NODES[@]}; i++ )); do
    kubectl label node "${NODES[$i]}" --overwrite node-role.kubernetes.io/node=
done
sleep 2
kubectl get nodes -o wide

echo
${SCRIPTDIR}/21-setupDnsmasq.sh traefik-ingress
