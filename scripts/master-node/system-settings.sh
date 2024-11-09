# k3sからiptablesでブリッジのトラフィックを制御できるよう設定
cat <<EOF >/etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system

# パッケージの最新化
apt update && apt -y upgrade

# k3sインストールの事前セットアップ
if [[ "${SETUP_SERVER}" == "PRIMARY" ]]; then
  bash pre-install-k3s.sh
fi

# 再起動
reboot -h
