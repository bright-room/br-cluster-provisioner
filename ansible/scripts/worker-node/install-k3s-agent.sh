#! /bin/bash

set -euo pipefail
cd "$(dirname "${0}")"

# 必要なディレクトリを作成
sudo mkdir -p /etc/rancher/k3s
sudo chown bradmin:bradmin -R /etc/rancher

# kubelet-configの設定
cat <<EOF > /etc/rancher/k3s/kubelet.config
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
shutdownGracePeriod: 30s
shutdownGracePeriodCriticalPods: 10s
EOF

# k3sの設定
cat <<EOF > /etc/rancher/k3s/config.yaml
token: ${K3S_CLUSTER_TOKEN}
node-label:
  - 'node_type=worker'
kubelet-arg:
  - 'config=/etc/rancher/k3s/kubelet.config'
kube-proxy-arg:
  - 'metrics-bind-address=0.0.0.0'
EOF

# k3s-agentの起動
curl -sfL https://get.k3s.io | sh -s - agent --server https://172.22.10.1:6443
