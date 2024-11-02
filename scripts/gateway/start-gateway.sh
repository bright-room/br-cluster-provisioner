#! /bin/bash

set -euo pipefail
cd "$(dirname "${0}")"

# Gatewayの機能として必要な資材を持ち込む
mkdir /works
git clone https://github.com/bright-room/br-cluster-gateway-services.git /works/br-cluster-gateway-services
chown -R bradmin:bradmin /works/br-cluster-gateway-services

cd /works/br-cluster-gateway-services

# 後続のsystemd-resolveの無効化をする前にやらないとネットに繋がらなくなるため先に色々仕込んでおく
docker compose build
docker compose pull

# systemd-resolvedを停止
systemctl stop systemd-resolved
systemctl disable systemd-resolved

# 起動
docker compose up -d
