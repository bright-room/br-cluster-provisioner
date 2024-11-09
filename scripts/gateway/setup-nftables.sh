#! /bin/bash

set -euo pipefail
cd "$(dirname "${0}")"

# ディレクトリを作成
mkdir /etc/nftables.d

# ルールセット作成
cat <<'EOF' > /etc/nftables.conf
#!/usr/sbin/nft -f

# 設定の初期化
flush ruleset

include "/etc/nftables.d/defines.nft"

table inet filter {
    chain global {
        # state management
        ct state established,related accept
        ct state invalid drop
    }
    include "/etc/nftables.d/sets.nft"
    include "/etc/nftables.d/filter-input.nft"
    include "/etc/nftables.d/filter-output.nft"
    include "/etc/nftables.d/filter-forward.nft"
}

# NAT変換用のテーブル定義
table ip nat {
    include "/etc/nftables.d/sets.nft"
    include "/etc/nftables.d/nat-prerouting.nft"
    include "/etc/nftables.d/nat-postrouting.nft"
}
EOF

# 変数定義
cat <<'EOF' > /etc/nftables.d/defines.nft
# ブロードキャストとマルチキャストの定義(IPv4)
define badcast_addr = { 255.255.255.255, 224.0.0.1, 224.0.0.251 }

# ブロードキャストとマルチキャストの定義(IPv6)
define ip6_badcast_addr = { ff02::16 }

# インバウンドを許可するTCP通信
define in_tcp_accept = { ssh, https, http, iscsi-target, 2379, 6443 }

# インバウンドを許可するUDP通信
define in_udp_accept = { snmp, domain, ntp, bootps }

# アウトバウンドを許可するTCP通信
define out_tcp_accept = { http, https, ssh }

# アウトバウンドを許可するUDP通信
define out_udp_accept = { domain, bootps , ntp }

# LAN側のインターフェース定義
define lan_interface = eth0

# WAN側のインターフェース定義
define wan_interface = wlan0

# dockerのインターフェース定義
define docker_interface = { docker0 }

# LAN側のネットワーク定義
define lan_network = 172.22.10.0/24

# フォワードを許可するTCP通信
define forward_tcp_accept = { http, https, ssh }

# フォワードを許可するUDP通信
define forward_udp_accept = { domain, ntp }
EOF

# 型付けされた変数セット
cat <<'EOF' > /etc/nftables.d/sets.nft
set blackhole {
    type ipv4_addr;
    elements = $badcast_addr
}

set forward_tcp_accept {
    type inet_service; flags interval;
    elements = $forward_tcp_accept
}

set forward_udp_accept {
    type inet_service; flags interval;
    elements = $forward_udp_accept
}

set in_tcp_accept {
    type inet_service; flags interval;
    elements = $in_tcp_accept
}

set in_udp_accept {
    type inet_service; flags interval;
    elements = $in_udp_accept
}

set ip6blackhole {
    type ipv6_addr;
    elements = $ip6_badcast_addr
}

set out_tcp_accept {
    type inet_service; flags interval;
    elements = $out_tcp_accept
}

set out_udp_accept {
    type inet_service; flags interval;
    elements = $out_udp_accept
}
EOF

# インバウンド側のトラフィックフィルタリングルール
cat <<'EOF' > /etc/nftables.d/filter-input.nft
chain input {
    # policy
    type filter hook input priority 0; policy drop;

    # global
    jump global

    # localhost
    iif lo accept

    # icmp
    meta l4proto {icmp,icmpv6} accept

    # input udp accepted
    udp dport @in_udp_accept ct state new accept

    # input tcp accepted
    tcp dport @in_tcp_accept ct state new accept
}
EOF

# アウトバウンド側のトラフィックフィルタリングルール
cat <<'EOF' > /etc/nftables.d/filter-output.nft
chain output {
    # policy: Allow any output traffic
    type filter hook output priority 0;
}
EOF

# フォワーディングのトラフィックフィルタリングルール
cat <<'EOF' > /etc/nftables.d/filter-forward.nft
chain forward {
    # policy
    type filter hook forward priority 0; policy drop;

    # global
    jump global

    # lan to wan tcp
    iifname $lan_interface ip saddr $lan_network oifname $wan_interface tcp dport @forward_tcp_accept ct state new accept

    # lan to wan udp
    iifname $lan_interface ip saddr $lan_network oifname $wan_interface udp dport @forward_udp_accept ct state new accept

    # ssh from wan
    iifname $wan_interface oifname $lan_interface ip daddr $lan_network tcp dport ssh ct state new accept

    # http from wan
    iifname $wan_interface oifname $lan_interface ip daddr $lan_network tcp dport {http, https} ct state new accept

    # docker
    ct state { established, related } accept;
    ct state invalid drop;

    iifname $docker_interface accept;
}
EOF

# NATプレルーティングルール
cat <<'EOF' > /etc/nftables.d/nat-prerouting.nft
chain prerouting {
    # policy
    type nat hook prerouting priority 0;
}
EOF

# NATポストルーティングルール
cat <<'EOF' > /etc/nftables.d/nat-postrouting.nft
chain postrouting {
    # policy
    type nat hook postrouting priority 100;

    # masquerade lan to wan
    ip saddr $lan_network oifname $wan_interface masquerade
    oifname != $docker_interface masquerade;
}
EOF

# 設定ファイルに実行権限を与える
chmod u+x /etc/nftables.conf
chmod u+x /etc/nftables.d/*

# 設定を読み込み
nft -f /etc/nftables.conf
netfilter-persistent save

# 自動起動を有効にする
systemctl enable nftables

# nft list ruleset