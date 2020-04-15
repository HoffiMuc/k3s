#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPOROOTDIR=${SCRIPTDIR%/*}

# defines NODES array
source "$SCRIPTDIR/00-setupVars.sh"

finish() {
    errorcode=$?
    set +x
    return $errorcode
}
trap finish EXIT

SKIP="false"
if [[ "$1" = "skip" ]]; then shift ; SKIP="true" ; fi

echo $0
echo ${0//?/=}
echo

set -ue
set -x

# Create containers
if [[ "${SKIP}" = "false" ]]; then
    for NODE in "${NODES[@]}"; do
        multipass launch --name "${NODE}" --cpus 2 --mem 2G --disk 5G ${MULTIPASSBASEOS};
    done
    # Wait a few seconds for nodes to be up
    sleep 7
fi


set +x
echo "############################################################################"
echo "multipass containers installed:"
multipass ls
echo "############################################################################"
echo
echo "./hosts and /etc/hosts append ip addresses of VMs enp0s2 network interface:"
for NODE in "${NODES[@]}"; do
	( multipass exec "${NODE}" -- bash -c 'printf "%s %s\n" $(ifconfig enp0s2 | grep "inet addr" | cut -d ":" -f 2 | cut -d " " -f 1) $(hostname)' ) | tee -a "${REPOROOTDIR}/hosts"
done
cat "${REPOROOTDIR}/hosts" | sudo tee -a /etc/hosts

set -x

for NODE in "${NODES[@]}"; do
    multipass transfer "${REPOROOTDIR}/hosts" "${NODE}":/tmp/
    multipass exec "${NODE}" -- sudo iptables -P FORWARD ACCEPT
    multipass exec "${NODE}" -- bash -c 'sudo chown ubuntu:ubuntu /etc/hosts'
    multipass exec "${NODE}" -- bash -c 'sudo cat /tmp/hosts >> /etc/hosts'
    multipass transfer ~/.ssh/id_rsa.pub "${NODE}":/tmp/
    multipass exec "${NODE}" -- bash -c 'sudo cat /tmp/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys'
    # add self-signed cert
    sudo multipass transfer "${CERT_FILENAME}" ${NODE}:/tmp/
    multipass exec "${NODE}" -- sudo mv /tmp/${CERT_FILENAME##*/} /usr/local/share/ca-certificates/
    multipass exec "${NODE}" -- sudo update-ca-certificates
    # temporary edit /etc/resolv.conf nameserver
    multipass exec "${NODE}" -- bash -c "sudo sed -i\".bak\" -r \"0,/^nameserver .*/ s/^nameserver .*/nameserver ${DNSSERVER}/\" /etc/resolv.conf"
done
