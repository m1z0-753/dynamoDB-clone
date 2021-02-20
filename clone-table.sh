#!/bin/bash

# 元テーブルのテーブル定義から、create-table用のテーブル定義ファイルを作成する
get_table_data() {
	echo "get_table_data start"
  # AWSから元テーブルのテーブル定義を取得してファイルに出力
  aws dynamodb describe-table --table-name ${original_table_name} > ${original_table_file}

  # AWSから出力したテーブル定義を、create-tableに使用できる形に成形してファイルに出力
  cat ${original_table_file} |
  jq '.Table' |
  jq '.TableName = "'${new_table_name}'"' |
  jq 'del(.TableStatus)' |
  jq 'del(.CreationDateTime)' |
  jq 'del(.ProvisionedThroughput.LastIncreaseDateTime)' |
  jq 'del(.ProvisionedThroughput.NumberOfDecreasesToday)' |
  jq 'del(.TableSizeBytes)' |
  jq 'del(.ItemCount)' |
  jq 'del(.TableArn)' |
  jq 'del(.TableId)' |
  jq 'del(.LatestStreamLabel)' |
  jq 'del(.LatestStreamArn)' |
  jq 'del(.GlobalSecondaryIndexes[]?.IndexStatus)' |
  jq 'del(.GlobalSecondaryIndexes[]?.IndexSizeBytes)' |
  jq 'del(.GlobalSecondaryIndexes[]?.ItemCount)' |
  jq 'del(.GlobalSecondaryIndexes[]?.IndexArn)' |
  jq 'del(.GlobalSecondaryIndexes[]?.ProvisionedThroughput.NumberOfDecreasesToday)' > ${new_table_file}
}

# 元テーブルのテーブル定義ファイルを元に、テスト用のテーブルを新規作成する
create_table() {
	echo "create_table start"
  aws dynamodb create-table --cli-input-json file://${new_table_file}
}

# 元テーブルに登録されているアイテム情報を、ファイルに出力する
get_items_data() {
  echo "get_items_data start"
  aws dynamodb scan --table-name ${table_name} > ${original_items_file}
}

# 元テーブルのアイテム情報ファイルを元に、テスト用のテーブルにアイテムを登録する
put_items() {
	echo "put_items start"
  # 登録対象のアイテム数
  item_length=$(cat ${original_items_file} | jq ".Items | length")

  # アイテム数 > 0 の場合のみ、テスト用テーブルにアイテムを登録する
  # (アイテムが無いのに put-itemコマンド実行しようとするとエラーになるので)
  if [ ${item_length} -gt 0 ]; then
    for i in $( seq 0 $((${item_length} - 1)) ); do
      item=$(cat ${original_items_file} | jq ".Items[${i}]")
      aws dynamodb put-item --table-name ${new_table_name} --item "${item}"
    done
  fi
}

# テスト用に複製するテーブル群のテーブル名を指定
target_tables=("TABLE-A" "TABLE-B" "TABLE-C")

for table_name in ${target_tables[@]}; do
  # テーブル名
  original_table_name=${table_name}
  new_table_name=clone-${original_table_name}

  # テーブル定義ファイル名
  original_table_file=original_table_${original_table_name}.json
  new_table_file=new_table_${new_table_name}.json

  # アイテム情報ファイル名
  original_items_file=original_items_${original_table_name}.json

  get_table_data
  create_table
  
  get_items_data
  # テーブルの作成が完了する前にItemを入れようとするとResourceNotFoundExceptionが発生するので、遅延をいれる
  echo "sleep 20 start"
  sleep 20
	echo "sleep 20 end"
  put_items
done
