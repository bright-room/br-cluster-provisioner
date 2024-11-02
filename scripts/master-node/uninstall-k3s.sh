#! /bin/bash

set -euo pipefail
cd "$(dirname "${0}")"

# ネットワークからciliumを削除
ip link delete cilium_host
ip link delete cilium_net
ip link delete cilium_vxlan
iptables-save | grep -iv cilium | iptables-restore
ip6tables-save | grep -iv cilium | ip6tables-restore

# K3s-masterのアンインストール
/usr/local/bin/k3s-uninstall.sh
