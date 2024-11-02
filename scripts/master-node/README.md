# Masterノードのセットアップ

## システム設定

rootユーザーで実施する

```shell
# Primaryの場合
bash system-settings.sh --primary

# secondaryの場合
bash system-settings.sh
```

このシェル終了後再起動される

## k3sのインストール

### Primary

マシンが起動したらbradminで実施する

```shell
# Primaryの場合
bash install-k3s.sh --primary

# secondaryの場合
bash install-k3s.sh
```

## Workerノードにロールを付与

bradminで実施する

```shell
bash roleup-k3s.sh
```


## k3s-agentのアンインストール

bradminで実施する

```shell
bash uninstall-k3s.sh
```
