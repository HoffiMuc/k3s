#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# defines NODES array
source "$SCRIPTDIR/01-setupVars.sh"

finish() {
    set +x
}
trap finish EXIT

set -e
set -x

# Create containers
for NODE in "${NODES[@]}"; do multipass launch --name "${NODE}" --cpus 2 --mem 4G --disk 10G; done

# Wait a few seconds for nodes to be up
sleep 5

echo "############################################################################"
echo "multipass containers installed:"
multipass ls
echo "############################################################################"

# Print nodes ip addresses
for NODE in "${NODES[@]}"; do
	multipass exec "${NODE}" -- bash -c 'echo -n "$(hostname) " ; ip -4 addr show enp0s2 | grep -oP "(?<=inet ).*(?=/)"'
	multipass exec "${NODE}" -- bash -c 'ip -4 addr show enp0s2 | grep -oP "(?<=inet ).*(?=/)";echo -n "$(hostname) "'
	# IPADDR=ip a show enp0s2 | grep "inet " | awk '{print $2}' | cut -d / -f1
    # IPADDR=$(ifconfig | sed -n -E 's/.*inet (192.168.64.[0-9]*).*/\1/p')
done

# Create the hosts file
# multipass exec node1 -- bash -c 'echo `ls /sys/class/net | grep en`' > nic_name
# nic_name=`cat nic_name`
for NODE in "${NODES[@]}"; do
    # multipass exec ${NODE} -- bash -c 'echo `ip -4 addr show enp0s2 | grep -oP "(?<=inet ).*(?=/)"` `echo $(hostname)` | sudo tee -a /etc/hosts'
    multipass exec "${NODE}" -- bash -c 'echo `ip -4 addr show enp0s2 | grep -oP "(?<=inet ).*(?=/)"` `echo $(hostname)`'
    # multipass exec ${NODE} -- bash -c 'echo `ip -4 addr show $nic_name | grep -oP "(?<=inet ).*(?=/)"` `echo $(hostname)`'
    # on CentOS linux on some machines the nic is named ens3
    # multipass exec ${NODE} -- bash -c 'echo `ip -4 addr show ens3 | grep -oP "(?<=inet ).*(?=/)"` `echo $(hostname)`'
done > "$SCRIPTDIR/hosts"

echo "############################################################################"
echo "Writing multipass host entries to /etc/hosts on the VMs:"
cat hosts
echo "Now deploying k3s on multipass VMs"
echo "############################################################################"

for NODE in "${NODES[@]}"; do
    multipass transfer hosts "${NODE}":
    multipass transfer ~/.ssh/id_rsa.pub "${NODE}":
    multipass exec "${NODE}" -- sudo iptables -P FORWARD ACCEPT
    multipass exec "${NODE}" -- bash -c 'sudo cat /home/ubuntu/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys'
    multipass exec "${NODE}" -- bash -c 'sudo chown ubuntu:ubuntu /etc/hosts'
    multipass exec "${NODE}" -- bash -c 'sudo cat /home/ubuntu/hosts >> /etc/hosts'
done

echo "We need to write the host entries on your local machine to /etc/hosts"
echo "Please provide your sudo password:"
filepostfix=$(date +_%Y%m%d_%H%M%S)
sudo cp /etc/hosts /etc/hosts.backup.$filepostfix # backup file
cp /etc/hosts "$SCRIPTDIR/etchosts"
echo -e "\n\n===== $SCRIPTDIR $filepostfix ======" >> $SCRIPTDIR/etchosts
cat "$SCRIPTDIR/hosts" | sudo tee -a "$SCRIPTDIR/etchosts"
# workaround to get rid of characters appear as ^M in the hosts file (OSX Catalina)
tr '\r' '\n' < "$SCRIPTDIR/etchosts" > "$SCRIPTDIR/etchosts.unix"
sudo cp "$SCRIPTDIR/etchosts.unix" /etc/hosts

