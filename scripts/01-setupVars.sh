#!/usr/bin/env bash

export NODECOUNT=4
export NODENAMEPREFIX="node"

export NODES=( )

for (( i=0; i<${NODECOUNT}; i++ )); do
    >&2 echo "NODES[$i]=${NODENAMEPREFIX}$i"
    NODES[$i]="${NODENAMEPREFIX}$i"
done