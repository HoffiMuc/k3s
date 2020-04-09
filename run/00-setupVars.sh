#!/usr/bin/env bash

silent=false
if [[ ! -z $1 ]]; then
    silent=true
else
    echo
    echo "source run/00-setupVars.sh"
    echo "=========================="
fi

export NODECOUNT=4
export NODENAMEPREFIX="node"
export REGISTRY_NAMESPACE=registry-ns

#export MYCLUSTER_DOMAIN=mycluster.tld
export MYCLUSTER_DOMAIN=hoffimuc.com
export CERT_FILENAME=/etc/letsencrypt/live/${MYCLUSTER_DOMAIN}/fullchain.pem
export CERT_KEY_FILENAME=/etc/letsencrypt/live/${MYCLUSTER_DOMAIN}/privkey.pem

export NODES=( )

for (( i=0; i<${NODECOUNT}; i++ )); do
    if [[ ! silent ]]; then >&2 echo "NODES[$i]=${NODENAMEPREFIX}$i" ; fi
    NODES[$i]="${NODENAMEPREFIX}$i"
done

export KUBECONFIG=k3s.yaml
