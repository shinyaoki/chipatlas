#!/bin/sh
#$ -S /bin/sh

# 引数
# $1 : (入力) /home/okishinya/chipatlas/classification/ 配下の *_Statistics.*.tab
# $2 : (出力) トレーニング用のデータのファイルパス
# $3 : (出力) テスト用のデータのファイルパス

# 実行例
# sh textForMachineLearning.sh /home/okishinya/chipatlas/classification/ag_Statistics.hg19.tab path/to/antigen.hg19.training.tsv path/to/antigen.hg19.test.tsv


tail -n+2 "$1"| awk -F '\t' -v OFS='\t' '
BEGIN {
  while ((getline < "/home/okishinya/chipatlas/sh/abbreviationList_AG.tab") > 0) x[$1] = $2
  while ((getline < "/home/okishinya/chipatlas/sh/abbreviationList_CT.tab") > 0) x[$1] = $2
} $5 !~ "NoD@ " {
  class = x[substr($5, 1, 3)]
  subcl = substr($5, 6)
  before = $4
  gsub("\\|", "\t", $4)
  if (before != $5) print class, class "_____" subcl, $4 > "'"$2"'"
  else print "Unclassified", "Unclassified", $4 > "'"$3"'"
}'



