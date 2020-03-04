#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# defines NODES array
source "$SCRIPTDIR/01-setupVars.sh"

finish() {
    set +x
    if [[ -f "${SCRIPTDIR%/*}/k3s.yaml" ]]; then
        echo ""
        echo "export KUBECONFIG=${SCRIPTDIR%/*}/k3s.yaml"
    fi
}
trap finish EXIT

set -e
set -x

# if [[ ! -f "$SCRIPTDIR/k3s_install.sh" ]]; then
#     curl -sfL https://get.k3s.io > "$SCRIPTDIR/k3s_install.sh"
# fi
# for NODE in "${NODES[@]}"; do
#     multipass transfer "$SCRIPTDIR/k3s_install.sh" "${NODE}":
# done

# Deploy k3s master on node1
multipass exec "${NODES[0]}" -- /bin/bash -c "curl -sfL https://get.k3s.io | sh -"
# Get the IP of the master node
K3S_NODEIP_MASTER="https://$(multipass info "${NODES[0]}" | grep "IPv4" | awk -F' ' '{print $2}'):6443"
# Get the TOKEN from the master node
K3S_TOKEN="$(multipass exec "${NODES[0]}" -- /bin/bash -c "sudo cat /var/lib/rancher/k3s/server/node-token")"
# Deploy k3s on the worker nodes (all but the first in NODES array)
for (( i=1; i<${#NODES[@]}; i++ )); do
    multipass exec "${NODES[$i]}" -- /bin/bash -c "curl -sfL https://get.k3s.io | K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} sh -"
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
echo "done."
