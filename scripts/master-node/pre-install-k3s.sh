#! /bin/bash

set -euo pipefail
cd "$(dirname "${0}")"

# cilium-cliのインストール
cliArch=$(uname -m)
ciliumCliVersion=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${ciliumCliVersion}/cilium-linux-${cliArch}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${cliArch}.tar.gz.sha256sum
tar xzvfC cilium-linux-${cliArch}.tar.gz /usr/local/bin
rm -f cilium-linux-${cliArch}.tar.gz{,.sha256sum}

# helmのインストール
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
