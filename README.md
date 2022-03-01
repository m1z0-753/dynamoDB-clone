# DynamoDB Clone Script

## 前提

単にテーブルのクローンを作成したいだけであれば、
`テーブルの「バックアップ」→名前をつけて「復元」`
の方が数倍スマートかつ間違いないです。

## 使用するツール

- aws-cli
- jq

## 使い方

1. 59行目にクローンを作成するテーブル名を指定する
2. `bash clone-table.sh`で実行する

## 注意

- 起動するといくつかのjsonファイルが生成されます。実行中は削除しないでください。
スクリプト終了後は削除しても問題ありません。

- テーブルの作成に時間がかかる場合(インデックスがある時？)があるため、79行目で`sleep`を入れています。下記のエラーが出る場合は、ここを調整してください。

```log
An error occurred (ResourceNotFoundException) when calling the PutItem operation: Requested resource not found
```
