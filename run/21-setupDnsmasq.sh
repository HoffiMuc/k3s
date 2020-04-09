#!/usr/bin/env bash

# roughly based on https://itnext.io/setup-a-private-registry-on-k3s-f30404f8e4d3

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# defines MYCLUSTER_DOMAIN
source "$SCRIPTDIR/00-setupVars.sh"

finish() {
    errorcode=$?
    set +x
    return $errorcode
}
trap finish EXIT

echo $0
echo ${0//?/=}
echo

#UPDATE_WHAT=( "traefik-ingress" "docker-registry" )
UPDATE_WHAT=( "traefik-ingress" )
if [[ -n $1 ]]; then
    if [[ $1 =~ traefik-ingress|docker-registry ]]; then
        UPDATE_WHAT=( "$1" )
    else
        >&2 echo "unknown to setup dnsmasq config"
        exit 1
    fi
fi

if [[ ! -e /usr/local/etc/dnsmasq.conf ]]; then
    >&2 echo "/usr/local/etc/dnsmasq.conf does not exist!"
    exit 2
fi

somethingChanged="false"

set -ue
declare -i TRIES=20
for what in "${UPDATE_WHAT[@]}"; do
    sleep 1
    if [[ ${what} = "traefik-ingress" ]]; then
        for ((i=1;i<=$TRIES;i++)); do
            INGRESS_SVC_NODE_IP=$(kubectl -n kube-system get service/traefik | tail -n +2 | awk '{print $4}')
            if [[ "${INGRESS_SVC_NODE_IP}" =~ [0-9.]+ ]]; then
                break
            fi
            if [[ ${i} -eq 10 ]]; then >&2 echo "cannot get -n kube-system service/traefik external-IP, exiting..." ; exit 42 ; fi
            sleep 0.75
        done
        OLD_INGRESS_SVC_NODE_IP=$(sed -n -E "s#^address=/.${MYCLUSTER_DOMAIN}/([0-9.]*).*#\1#p" /usr/local/etc/dnsmasq.conf)
        echo "${OLD_INGRESS_SVC_NODE_IP} old -n kube-system service/traefik external-IP"
        echo "${INGRESS_SVC_NODE_IP} new -n kube-system service/traefik external-IP"
        echo
        if [[ ! "${OLD_INGRESS_SVC_NODE_IP}" = "${INGRESS_SVC_NODE_IP}" ]]; then
            sed -E -i .bak "s#^address=/.${MYCLUSTER_DOMAIN}/.*#address=/.${MYCLUSTER_DOMAIN}/${INGRESS_SVC_NODE_IP}#" /usr/local/etc/dnsmasq.conf
            somethingChanged="true"
        fi
    fi

#    if [[ ${what} = "docker-registry" ]]; then
#        if kubectl get namespace ${REGISTRY_NAMESPACE} > /dev/null 2>&1 ; then
#            for ((i=1;i<=$TRIES;i++)); do
#                REGISTRY_SVC_NODE_IP=$(kubectl -n ${REGISTRY_NAMESPACE} get service/docker-registry | tail -n +2 | awk '{print $4}')
#                if [[ "${REGISTRY_SVC_NODE_IP}" =~ [0-9.]+ ]]; then
#                    break
#                fi
#                if [[ ${i} -eq 10 ]]; then >&2 echo "cannot get -n ${REGISTRY_NAMESPACE} service/docker-registry external-IP, exiting..." ; exit 42 ; fi
#                sleep 0.75
#            done
#
#            OLD_REGISTRY_SVC_NODE_IP=$(sed -n -E "s#^address=/registry.${MYCLUSTER_DOMAIN}/([0-9.]*).*#\1#p" /usr/local/etc/dnsmasq.conf)
#
#            echo "${OLD_REGISTRY_SVC_NODE_IP} old -n ${REGISTRY_NAMESPACE} service/docker-registry external-IP"
#            echo "${REGISTRY_SVC_NODE_IP} new -n ${REGISTRY_NAMESPACE} service/docker-registry external-IP"
#
#            if [[ ! "${OLD_REGISTRY_SVC_NODE_IP}" = "${REGISTRY_SVC_NODE_IP}" ]]; then
#                sed -E -i .bak "s#^address=/registry.${MYCLUSTER_DOMAIN}/.*#address=/registry.${MYCLUSTER_DOMAIN}/${REGISTRY_SVC_NODE_IP}#" /usr/local/etc/dnsmasq.conf
#                somethingChanged="true"
#            fi
#        fi
#    fi

done

if [[ ${somethingChanged} = "true" ]]; then
    set -x
    sudo brew services restart dnsmasq
    echo
    set +x
fi

