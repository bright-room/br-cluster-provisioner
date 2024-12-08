#! /bin/bash

set -euo pipefail
cd "$(dirname "${0}")"

SETUP_SERVER="SECONDARY"
while [ $# -gt 0 ]; do
  case "$1" in
    -p | --primary)
        SETUP_SERVER="PRIMARY"
        ;;
    -s | --secondary)
        SETUP_SERVER="SECONDARY"
        ;;
    *)
        echo "Unknown argument: $1" >&2
        exit 1
        ;;
    esac
    shift
done

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
flannel-backend: none
disable-kube-proxy: true
disable-network-policy: true
disable:
  - local-storage
  - servicelb
  - traefik
  - metrics-server
etcd-expose-metrics: true
kube-controller-manager-arg:
  - bind-address=0.0.0.0
  - terminated-pod-gc-threshold=10
kube-proxy-arg:
  - metrics-bind-address=0.0.0.0
kube-scheduler-arg:
  - bind-address=0.0.0.0
kubelet-arg:
  - config=/etc/rancher/k3s/kubelet.config
node-taint:
  - node-role.kubernetes.io/master=true:NoSchedule
tls-san:
  - 172.22.10.1
write-kubeconfig-mode: 644
EOF

if [[ "${SETUP_SERVER}" == "PRIMARY" ]]; then
  # k3sの起動
  curl -sfL https://get.k3s.io | sh -s - server --cluster-init
else
  # k3sの起動
  curl -sfL https://get.k3s.io | sh -s - server --server https://172.22.10.60:6443
fi


