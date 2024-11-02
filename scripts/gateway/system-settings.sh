#! /bin/bash

set -euo pipefail
cd "$(dirname "${0}")"

# ホスト名を追加
echo "127.0.1.1 $(hostname)" >> /etc/hosts

# DNSを設定
mv /etc/resolv.conf /etc/resolv.conf.bk
cat <<EOF > /etc/resolv.conf
nameserver 172.22.10.1
nameserver 8.8.8.8
nameserver 8.8.4.4
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

# iptables-persistentをインストール時に手動で入力する項目を自動で入力するようにするための事前設定
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

# パッケージの最新化
apt update && apt -y upgrade

# 必要なパッケージをインストール
apt install -y \
  git \
  dnsutils \
  curl \
  ca-certificates \
  gnupg \
  netfilter-persistent \
  iptables-persistent \
  nftables \
  lsof \
  net-tools \
  jq

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl.sha256"

# docker
bash install-docker.sh

# IPフォワード有効化
sysctl -w net.ipv4.ip_forward=1 >> /etc/sysctl.conf

# nftablesの設定
bash setup-nftables.sh

# 再起動
reboot -h
