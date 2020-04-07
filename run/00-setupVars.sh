#!/usr/bin/env bash

silent=false
if [[ ! -z $1 ]]; then silent=true ; fi

export MYCLUSTER_DOMAIN=mycluster.tld
export NODECOUNT=4
export NODENAMEPREFIX="node"

export NODES=( )

for (( i=0; i<${NODECOUNT}; i++ )); do
    if [[ ! silent ]]; then >&2 echo "NODES[$i]=${NODENAMEPREFIX}$i" ; fi
    NODES[$i]="${NODENAMEPREFIX}$i"
done

export KUBECONFIG=k3s.yaml
