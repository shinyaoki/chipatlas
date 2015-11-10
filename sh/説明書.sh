# データのアップデート。
  sh chipatlas/sh/upDate.sh  # <<=== コマンド

# Curation のためのリストを作成。
  sh chipatlas/sh/listForClassify.sh  # <<=== コマンド

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
  
    checkCuration  # <<=== コマンド (Mac)

# 古い classification フォルダの移動
  スパコンで以下のコマンドを実行
  
    mv chipatlas/classification chipatlas/classification_201505 # 2015 5月の場合  <<=== コマンド
  
  これを Mac にダウンロードし、/Users/Oki/Desktop/沖　真弥/実験/chipAtlas/classification履歴 配下に移動させる。
  スパコンに Downloads/classification フォルダを chipatlas/ 配下にアップロード
  スパコンの chipatlas/classification_201505 は消去


# 新しい assembled ファイルの作成
  sh chipatlas/sh/bed4ToBed9.sh  # <<=== コマンド
  
    public 配下に .bed, .bed.idx が作られる
    chipatlas/lib/assembled_list 配下に experimentList.tab, fileList.tab が作られる。
    
    core dump があれば、以下のファイルが作られる。
      CAUTION_makeBigBed.txt
      
# colo, targetGenes の実行
  sh chipatlas/sh/dataAnalysis.sh  # <<=== コマンド

    colo の実行
    targetGenes の実行
    in silico ChIP 用の BED ファイルを作成、w3oki へ転送
    analysisList.tab の作成、全対応表を NBDC に送る。

# NBDC サーバにアップロード
