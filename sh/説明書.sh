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
  
    checkCuration

# 古い classification フォルダの移動
  スパコンで以下のコマンドを実行
  mv chipatlas/classification chipatlas/classification_201505 # 2015 5月の場合
  これを Mac にダウンロードし、/Users/Oki/Desktop/沖　真弥/実験/chipAtlas/classification履歴 配下に移動させる。
  スパコンに Downloads/classification フォルダを chipatlas/ 配下にアップロード
  スパコンの chipatlas/classification_201505 は消去


# 新しい assembled ファイルの作成
  sh chipatlas/sh/bed4ToBed9.sh
  
    public 配下に .bed, .bed.idx が作られる
    chipatlas/lib/assembled_list 配下に experimentList.tab, fileList.tab が作られる。
    
    core dump があったかどうかをチェックする。
    
      for fn in `ls makeBigBed_log/*log`; do
        if [ "`tail -n1 $fn`" != "Done" ]; then
          echo $fn
        fi
      done
      
# 新しい assembled ファイルの作成
  sh chipatlas/sh/bed4ToBed9.sh 



  
  
