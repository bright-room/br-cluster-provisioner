# br-cluster-provisioner

Raspberry Pi on kubernetes cluster で利用する各サーバーのプロビジョニングを管理するリポジトリ

## Architecture

- [docker](https://www.docker.com/ja-jp/)
- [1password connect](https://developer.1password.com/docs/connect/)
- [Ansible](https://docs.ansible.com/)

## 事前セットアップ

本リポジトリでは1password connectを活用してサーバー情報を取得してファイル生成をしているため、事前にconnect serverの接続に必要なcredentials情報が必須となる
作成方法については[こちら](https://developer.1password.com/docs/connect/get-started)を参照

作成したcredentials情報は以下に格納する  
環境毎に保管庫を分けているためそれぞれディレクトリを用意して確認証ファイルを以下のように配備する。

**dev環境**
- 1password-credentials.json
    - `.secret/dev/1password-credentials.json`
- Access token
    - `.secret/dev/.connect_token`にJWTトークンを貼り付ける

**prod環境**
- 1password-credentials.json
    - `.secret/prod/1password-credentials.json`
- Access token
    - `.secret/prod/.connect_token`にJWTトークンを貼り付ける

以下のコマンドで1password-connect群のコンテナを起動する

```shell
make bootstrap
```

## Clean

生成したファイルやコンテナ群を削除するには以下のコマンドを実行する

```shell
make clean
```
