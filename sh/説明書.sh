# Curation のためのリストを作成。
  sh chipatlas/sh/listForClassify.sh
  # < chipatlas/sh/ag_attributes.txt
  # < chipatlas/sh/ct_attributes.txt
  # > chipatlas/results/ce10/tag/SRX003825.tag.txt
  # > chipatlas/classification/ct_Statistics.mm9.tab
  # > chipatlas/classification/ag_Statistics.mm9.tab


# Curation の実行。
  chipatlas/classification を DL
  classification/ct_Statistics.mm9.tab を Google Refine で開く
  OR 支援ツール > 初期設定 をコピー
  Google Refine > Undo / Redo > Apply にペースト
  OR 支援ツール > Judge をコピー
  Google Refine > Judge タブ > Facet > Custom text facet にペースト

# Curation 終了後のチェック
  全てのファイルを tsv エクスポートし、Downloads/classification 配下に移動させる。
  以下のコマンドでチェック
{
  echo "行数 チェック"
  for fn in `ls Downloads/classification/*_Statistics-*-tab.tsv`; do
    echo `cat $fn| wc -l` `basename $fn`| tr ' ' '\t'
  done
  echo "@ がついているか？"
  for fn in `ls Downloads/classification/*_Statistics-*-tab.tsv`; do
    echo `basename $fn`
    tail -n+2 $fn| awk -F '\t' '{if ($5 !~ "@ ") print}'
  done
  echo "無駄なスペースがないか？"
  for fn in `ls Downloads/classification/*_Statistics-*-tab.tsv`; do
    echo `basename $fn`
    tail -n+2 $fn| awk -F '\t' '{if ($5 ~ "  " || $5 ~ / $/) print}'
  done
  echo "細胞タイプにハテナを忘れていないか？"
  for fn in `ls Downloads/classification/ct_Statistics-*-tab.tsv`; do
    echo `basename $fn`
    tail -n+2 $fn| awk -F '\t' '{if ($5 !~ "\\?" && $5 !~ "Unc@ ") print}'
  done
}

# 古い classification フォルダの移動
  スパコンで以下のコマンドを実行
  mv chipatlas/classification chipatlas/classification_201505 # 2015 5月の場合
  これを Mac にダウンロードし、/Users/Oki/Desktop/沖　真弥/実験/chipAtlas/classification履歴 配下に移動させる。
  スパコンに Downloads/classification フォルダを chipatlas/ 配下にアップロード
  スパコンの chipatlas/classification_201505 は消去


# 新しい assembled ファイルの作成
  sh chipatlas/sh/bed4ToBed9.sh 

  
  
