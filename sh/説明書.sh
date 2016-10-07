
# データのアップデート。
  sh chipatlas/sh/upDate.sh  # <<=== コマンド (DDBJ)
  
# run 中の time course の閲覧コマンド: wn timecourse4chipatlas

# 全部 run が終わったら、コアダンプや異常終了をチェック
  sh chipatlas/sh/checkCoreDump.sh  # <<=== コマンド (DDBJ, 時間がかかるので、ラボの Mac で実行)
# Unknown と表示された場合は検証が必要。Core dump と表示された場合は放置してよい  。
# また、FastQ == 0 の場合、通信障害やメモリ不足の可能性を調べる。そのような場合は  chipatlas/sh/reRunSraTailor.sh chipatlas を実行

# Curation のためのリストを作成。すぐに qsub になるので、どの Mac でも可能。
  sh chipatlas/sh/listForClassify.sh  # <<=== コマンド (DDBJ)

# 古い classification のバックアップ、個別データの転送
  backUpOldList 201610  # <<=== コマンド (ラボのMac, スパコンでない)
  transferDDBJtoNBDC eachData  # <<=== コマンド (ラボのMac)  個別データを NBDC に転送。
                               # 転送状況コマンド (ラボの Mac => nbdc =>): trfNBDC eachData.log

# Curation の実行。
  chipatlas/classification を DL
  Google Refine > Undo / Redo > Apply にペースト
  Google Refine > Judge タブ > Facet > Custom text facet にペースト

# Curation 終了後のチェック
  全てのファイルを tsv エクスポートし、Downloads/classification 配下に移動させる。
  以下のコマンドでチェック
  
    checkCuration  # <<=== コマンド (Mac)

  OK だったら、スパコンに Downloads/classification フォルダを chipatlas/ 配下にアップロード


# 新しい assembled ファイルの作成  (しばらく待つので、研究室の Mac から実行)
  sh chipatlas/sh/bed4ToBed9.sh  # <<=== コマンド (DDBJ しばらく待つので、研究室の Mac から実行)
  
    public 配下に .bed, .bed.idx が作られる
    chipatlas/lib/assembled_list 配下に experimentList.tab, fileList.tab が作られる。
    
    core dump があれば、以下のファイルが作られる。
      CAUTION_makeBigBed.txt
      
# colo, targetGenes の実行 (しばらく待つので、研究室の Mac から実行)
  transferDDBJtoNBDC assemble  # <<=== コマンド (ラボのMac)  assemble データを NBDC に転送 (2016/05/27 2.1 日)
                               # 転送状況コマンド (ラボの Mac => nbdc =>): trfNBDC assembled.log
  sh chipatlas/sh/dataAnalysis.sh  # <<=== コマンド (DDBJ しばらく待つので、研究室の Mac から実行)

    MarkDown の更新（手動）
    colo の実行
    targetGenes の実行
    in silico ChIP 用の BED ファイルを作成、w3oki へ転送
    in silico ChIP の実行
    analysisList.tab の作成
    
# NBDC サーバにアップロード, chipatlas の圧縮
  transferDDBJtoNBDC analysed  # <<=== コマンド (ラボのMac)  colo, target, 全対応表を NBDC に転送 (2016年 7月 12h)
                               # 転送状況コマンド (ラボの Mac => nbdc =>): trfNBDC analysed.log
#  echo "tar -c chipatlas| bin/pbzip2 > backUp_ChIP-Atlas.tar.bz2"| qsub -l month -l medium -e /dev/null -o /dev/null -N bu_pbzip2 -pe def_slot 10- # (7月 12 14:50-)

# MarkDown の更新
  データ数などのグラフが変わっているので、wiki でコピペ。

# 連絡
  大田さんと畠中先生に連絡する
  
  
# Wabi データの消去
  wabi              # <<=== コマンド (Mac)  w3oki アカウントにログイン
  deleteWabiResult  # <<=== コマンド (w3oki)  二週間前までのデータを消去

# 不要な tmp ファイルや log を消去
rm Controller.sh.[eo][0-9][0-9]*
rm TimeCourse.sh.[eo][0-9][0-9]*
rm upDate.sh.[eo][0-9][0-9]*
# rm UploadToServer_*.l[of]*
rm classify.log.txt
rm ncbi_error_report.xml
rm timecourse.chipatlas.txt
rm igv.log
# rm tmpFile4ggplot_chipatlas*.txt
# rm allDataNumber 
rm webList.sh.*
rm -r ncbi
rm -r tmpDirForColo
rm -r tmpDirForTargetGenes
# rm allDataNumber_old.tsv
rm CAUTION_makeBigBed.txt


##################################
# 部分解凍のしかた
mkdir backUp_ChIP-Atlas
cd backUp_ChIP-Atlas
tar xvjf ~/backUp_ChIP-Atlas.tar.bz2 "chipatlas/hoge/hage.bw" "chipatlas/foo/baa.bed" # 複数ファイル指定可能



# qchange 可能
targetGene
preProcess
FF_Enhance
FF_Pr_hg19
FF_Pr_mm9
GWAS (month 可)
iscGWAS (month 可)
hg19Prom (month 可)
mm9Prom (month 可)
R_fantomEn (month 不可)
R_FPmm9 (month 不可)
R_FPhg19 (month 不可)

# qchange 不可能
trfB2w3
coLocaliza

