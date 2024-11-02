#! /bin/bash

set -euo pipefail
cd "$(dirname "${0}")"

kubectl label nodes br-node4 kubernetes.io/role=worker
kubectl label nodes br-node5 kubernetes.io/role=worker
kubectl label nodes br-node6 kubernetes.io/role=worker
