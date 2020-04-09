#!/usr/bin/env bash

# to bind to all interfaces on remote machine (0.0.0.0)
# on remote machine, you need to have socat installed
# and /etc/ssh/sshd_config configuration:
# GatewayPorts clientspecified
# or
# GatewayPorts yes
ssh -t -i ~/.ssh/dhoffiEMC \
    -R 0.0.0.0:8888:0.0.0.0:80 \
    -R 0.0.0.0:8443:0.0.0.0:443 \
    hoffi@138.68.103.147 -- \
    "(sudo socat TCP-LISTEN:80,fork TCP:localhost:8888) & sudo socat TCP-LISTEN:443,fork TCP:localhost:8443"
