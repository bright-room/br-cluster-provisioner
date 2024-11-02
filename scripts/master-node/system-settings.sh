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

# ホスト名を追加
echo "127.0.1.1 $(hostname)" >> /etc/hosts

# DNSを設定
mv /etc/resolv.conf /etc/resolv.conf.bk
cat <<EOF > /etc/resolv.conf
nameserver 172.22.10.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# k3sからiptablesでブリッジのトラフィックを制御できるよう設定
cat <<EOF >/etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# cgroupの有効化
sed -i -e "1 s/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/g" /boot/firmware/cmdline.txt

# GPUメモリの割り当てサイズを変更
echo "gpu_mem=16" >> /boot/firmware/config.txt

# スワップの無効化
swapoff --all

# snapパッケージの削除
packageList=$(snap list | awk '!/Name/{print $1}')
for package in ${packageList};do
  snap remove ${package}
done

# 不要なパッケージを削除
apt purge -y \
  snapd \        # snapパッケージの削除
  needrestart    # apt upgradeを行うたびに、Pending kernel upgrade と表示されてしまうのでその対処

apt autoremove -y

# NTP設定の変更
sed -i -e "s/#NTP=/NTP=ntp1.bright-room.internal/g" /etc/systemd/timesyncd.conf
timedatectl set-timezone Asia/Tokyo

# パッケージの最新化
apt update && apt -y upgrade

# k3sインストールの事前セットアップ
if [[ "${SETUP_SERVER}" == "PRIMARY" ]]; then
  bash pre-install-k3s.sh
fi

# 再起動
reboot -h
