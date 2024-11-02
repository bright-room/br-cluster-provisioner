#! /bin/bash

set -euo pipefail
cd "$(dirname "${0}")"

# 公式DockerのGPG-keyを追加
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Dockerリポジトリを追加
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# パッケージの最新化
apt update && apt -y upgrade

# インストール
apt update
apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# dockerグループに運用ユーザーを追加
if [[ $(grep -c docker /etc/group) -eq 0 ]]; then
  groupadd docker
fi
gpasswd -a bradmin docker

# docker内で利用するDNSを追加
cat <<'EOF' > /etc/docker/daemon.json
{
    "dns": ["8.8.8.8", "8.8.4.4"],
    "iptables": false
}
EOF