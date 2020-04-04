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
    fi
    return $errorcode
}
trap finish EXIT

LOCALK3SBIN=''
if [[ "$1" = "local" ]]; then
    # you can edit and use ./run/k3sLocalScript/k3sDownload.sh
    LOCALK3SBIN=/tmp/k3s.bin
fi

set -ue
set -x

# Deploy k3s master on node0
echo ""
if [[ -z "$LOCALK3SBIN" ]]; then
    multipass exec "${NODES[0]}" -- /bin/bash -c "curl -fL -C - https://get.k3s.io | sh -"
else
    multipass transfer ${SCRIPTDIR}/k3sLocalScript/k3sInstall.sh ${NODES[0]}:/tmp/install.sh
    multipass transfer ${LOCALK3SBIN} ${NODES[0]}:/tmp/k3s.bin
    multipass exec "${NODES[0]}" -- /bin/chmod 755 /tmp/install.sh
    multipass exec "${NODES[0]}" -- /bin/chmod 755 /tmp/k3s.bin
    multipass exec "${NODES[0]}" -- /bin/bash -c "sh /tmp/install.sh local"
fi
# Get the IP of the master node
K3S_NODEIP_MASTER="https://$(multipass info "${NODES[0]}" | grep "IPv4" | awk -F' ' '{print $2}'):6443"
# Get the TOKEN from the master node
K3S_TOKEN="$(multipass exec "${NODES[0]}" -- /bin/bash -c "sudo cat /var/lib/rancher/k3s/server/node-token")"
# Deploy k3s on the worker nodes (all but the first in NODES array)
for (( i=1; i<${#NODES[@]}; i++ )); do
    echo ""
    if [[ -z "$LOCALK3SBIN" ]]; then
        multipass exec "${NODES[$i]}" -- /bin/bash -c "curl -sfL -C - https://get.k3s.io | K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} sh -"
    else
        multipass transfer ${SCRIPTDIR}/k3sLocalScript/k3sInstall.sh ${NODES[$i]}:/tmp/install.sh
        multipass transfer ${LOCALK3SBIN} ${NODES[$i]}:/tmp/k3s.bin
        multipass exec "${NODES[$i]}" -- /bin/chmod 755 /tmp/install.sh
        multipass exec "${NODES[$i]}" -- /bin/chmod 755 /tmp/k3s.bin
        multipass exec "${NODES[$i]}" -- /bin/bash -c "K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} sh /tmp/install.sh local"
    fi
done
sleep 10

echo "############################################################################"
# multipass exec node1 -- bash -c "sudo kubectl get nodes"
multipass exec "${NODES[0]}" -- bash -c 'sudo cat /etc/rancher/k3s/k3s.yaml' > "${SCRIPTDIR%/*}/k3s.yaml"
sed -i'.back' -e "s/127.0.0.1/${NODES[0]}/g" "${SCRIPTDIR%/*}/k3s.yaml"
export KUBECONFIG="${SCRIPTDIR%/*}/k3s.yaml"
kubectl taint node "${NODES[0]}" node-role.kubernetes.io/master=effect:NoSchedule
for (( i=1; i<${#NODES[@]}; i++ )); do
    kubectl label node "${NODES[$i]}" node-role.kubernetes.io/node=
done
sleep 2
kubectl get nodes
