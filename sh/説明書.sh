# データのアップデート。
  sh chipatlas/sh/upDate.sh  # <<=== コマンド (DDBJ)

# 全部 run が終わったら、残った SRX フォルダがコアダンプかどうかをチェック
# Unknown と表示された場合は検証が必要。Core dump と表示された場合は放置してよい  。
  sh chipatlas/sh/checkCoreDump.sh  # <<=== コマンド (DDBJ)

# Curation のためのリストを作成。
  sh chipatlas/sh/listForClassify.sh  # <<=== コマンド (DDBJ)
  sh chipatlas/sh/transferDDBJtoNBDC.sh "eachData"  # <<=== コマンド (DDBJ)  個別データを NBDC に転送

# Curation の実行。
  chipatlas/classification を DL
  Google Refine > Undo / Redo > Apply にペースト
  Google Refine > Judge タブ > Facet > Custom text facet にペースト

# Curation 終了後のチェック
  全てのファイルを tsv エクスポートし、Downloads/classification 配下に移動させる。
  以下のコマンドでチェック
  
    checkCuration  # <<=== コマンド (Mac)

# 古い classification フォルダやリストのバックアップ
  sh chipatlas/sh/backUpOldList.sh 201509  # <<=== コマンド (DDBJ)

  スパコンに Downloads/classification フォルダを chipatlas/ 配下にアップロード


# 新しい assembled ファイルの作成
  sh chipatlas/sh/bed4ToBed9.sh  # <<=== コマンド (DDBJ)
  
    public 配下に .bed, .bed.idx が作られる
    chipatlas/lib/assembled_list 配下に experimentList.tab, fileList.tab が作られる。
    
    core dump があれば、以下のファイルが作られる。
      CAUTION_makeBigBed.txt
      
# colo, targetGenes の実行
  sh chipatlas/sh/dataAnalysis.sh  # <<=== コマンド (DDBJ)
  sh chipatlas/sh/transferDDBJtoNBDC.sh "assemble"  # <<=== コマンド (DDBJ)  assemble データを NBDC に転送

    colo の実行
    targetGenes の実行
    in silico ChIP 用の BED ファイルを作成、w3oki へ転送
    analysisList.tab の作成
    
# NBDC サーバにアップロード
  sh chipatlas/sh/transferDDBJtoNBDC.sh "analysed"  # <<=== コマンド (DDBJ)  colo, target, 全対応表を NBDC に転送

# Wabi データの消去
  wabi              # <<=== コマンド (Mac)  w3oki アカウントにログイン
  deleteWabiResult  # <<=== コマンド (w3oki)  二週間前までのデータを消去

# 不要な tmp ファイルや log
UploadToServer_assemble.lftp
UploadToServer_assemble.log
UploadToServer_eachData.lftp
UploadToServer_eachData.log
UploadToServer_analysed.lftp
UploadToServer_analysed.log
tmpDirForColo
tmpDirForTargetGenes
tmpDirFortransferBedTow3oki


