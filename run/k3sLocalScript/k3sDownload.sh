#!/usr/bin/env bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

set -x
curl -o /tmp/k3s.bin -fL -C - "https://github.com/rancher/k3s/releases/tag/v1.17.4+k3s1"
set +x
