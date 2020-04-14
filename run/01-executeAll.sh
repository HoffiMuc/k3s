#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

finish() {
    errorcode=$?
    set +x
    return $errorcode
}
trap finish EXIT

SKIP="false"
if [[ "$1" = "skip" ]]; then shift ; SKIP="true" ; fi

#read -p "reset nameserver ??? " -n 1 -r
echo "reset nameserver ??? "
echo -n "please provide sudo password for later: "
echo "$(sudo whoami)" > /dev/null
echo

set -ue
set -x

if [[ "$SKIP" != "true" ]]; then
    time ${SCRIPTDIR}/02-setupVMs.sh
fi
time ${SCRIPTDIR}/03-setupK3s.sh $1
sleep 5
${SCRIPTDIR}/21-setupDnsmasq.sh traefik-ingress
time ${SCRIPTDIR}/04-firstTimeK3sConfig.sh
time ${SCRIPTDIR}/05-setupCertMgr.sh
#time ${SCRIPTDIR}/10-setupMetalLB.sh
time ${SCRIPTDIR}/20-setupRegistry.sh # calls ${SCRIPTDIR}/21-setupDnsmasq.sh
