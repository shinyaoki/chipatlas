
# データのアップデート。
  upDateNCBI # <<=== コマンド (DDBJ, iMac, MacBook) 最新の Metadata のバージョン check
  sh chipatlas/sh/upDate.sh  # <<=== コマンド (DDBJ) すぐに qsub されるので、どの mac でも可能
  
# run 中の time course の閲覧コマンド: wn timecourse4chipatlas

# 全部 run が終わったら、コアダンプや異常終了をチェック
  sh chipatlas/sh/checkCoreDump.sh  # <<=== コマンド (DDBJ, 時間がかかるので、ラボの Mac で実行)
# Unknown と表示された場合は検証が必要。時間切れなどが考えられる。
# Core dump, Time out と表示された場合は放置してよい。
# また、FastQ == 0 の場合、通信障害やメモリ不足の可能性を調べる。そのような場合は  chipatlas/sh/reRunSraTailor.sh chipatlas を実行
# それ以外の例外などで再実行したいときは Conntroller.sh の末尾を参照。

# Curation のためのリストを作成。すぐに qsub になるので、どの Mac でも可能。
  sh chipatlas/sh/listForClassify.sh  # <<=== コマンド (DDBJ)

# 古い classification のバックアップ、個別データの転送
  backUpOldList 201902  # <<=== コマンド (ラボのMac, スパコンでない。実行した月を入力)
  transferDDBJtoNBDC eachData  # <<=== コマンド (ラボのMac)  個別データを NBDC に転送。
                               # 転送状況コマンド (ラボの Mac => nbdc =>): trfNBDC eachData.log

# 機械学習による curation 予測 
  sh chipatlas/sh/ML_curation.sh initial  # <<=== コマンド (DDBJ) すぐに qsub されるので、どの mac でも可能。半日くらいかかる。
  
# Curation の実行。
  chipatlas/classification を DL
  Google Refine > Undo / Redo > Apply にペースト
  Google Refine > Judge タブ > Facet > Custom text facet にペースト
  #!!! Curator のキャッシュを削除 !!!
      Safari > 環境設定 > プライバシー > Web サイトデータを管理 > "biosciencedbc.jp" を削除
  

# Curation 終了後のチェック
  全てのファイルを tsv エクスポートし、Downloads/classification 配下に移動させる。
  以下のコマンドでチェック
  
    checkCuration  # <<=== コマンド (iMac)

  OK だったら、スパコンに Downloads/classification フォルダを chipatlas/ 配下にアップロード


# 新しい assembled ファイルの作成
  qsub -e /dev/null -o /dev/null chipatlas/sh/bed4ToBed9.sh  # <<=== コマンド (DDBJ) すぐに qsub されるので、どの mac でも可能。半日くらいかかる。
  
    public 配下に .bed, .bed.idx が作られる
    allPeaks_light 配下に allPeaks_light.bed がつくられる。
    chipatlas/lib/assembled_list 配下に experimentList.tab, fileList.tab が作られる。
    
    core dump があれば、以下のファイルが作られる。
      CAUTION_makeBigBed.txt
      
# colo, targetGenes の実行 (しばらく待つので、研究室の Mac から実行)
  transferDDBJtoNBDC assemble  # <<=== コマンド (ラボのMac)  assemble データを NBDC に転送 (2016/05/27 2.1 日)
                               # 転送状況コマンド (ラボの Mac => nbdc =>): trfNBDC assembled.log
  sh chipatlas/sh/dataAnalysis.sh  # <<=== コマンド (DDBJ しばらく待つので、研究室の Mac から実行)

    MarkDown の更新（手動）
    colo の実行  # 2017年 8月 : 22 日間, 9月 : 16 日 (month_hdd.q), 9月 : 17 日 (month_ssd.q)  !!! week node のほうが CPU 性能が良く早いかも。
    targetGenes の実行
    in silico ChIP 用の BED ファイルを作成、w3oki へ転送
    in silico ChIP の実行
    analysisList.tab の作成
    
# CoLo 終了後、analysisList.tab の作成。すぐに qsub になるので、どの Mac でも可能。
  qsub -o /dev/null -e /dev/null chipatlas/sh/dataAnalysis.sh -l chipatlas
# NBDC サーバにアップロード, chipatlas の圧縮
  transferDDBJtoNBDC analysed  # <<=== コマンド (ラボのMac)  colo, target, 全対応表, またその他の非公開用の全ファイルを NBDC に転送 (2016年 7月 12h)
                               # 転送状況コマンド (ラボの Mac => nbdc =>): trfNBDC analysed.log
# echo "tar -c chipatlas| bin/pbzip2 > backUp_ChIP-Atlas.tar.bz2"| qsub -l month -l medium -e /dev/null -o /dev/null -N bu_pbzip2 -pe def_slot 10-
# echo "cd striped_18; split -a3 backUp_ChIP-Atlas.tar.bz2 -b 10000000000 backUp_ChIP-Atlas.tar.bz2_"| qsub -l month -l medium -e /dev/null -o /dev/null -N split_pbzip2 # (6/20 14:42-)


# MarkDown の更新
  データ数などのグラフが変わっているので、wiki でコピペ。

# 引用論文の更新
  Mendelay に追加し、ChIP-Atlas citations Markdown というスタイルでコピーし、"ctm" というコマンドを実行して、下記にペースト
  https://github.com/inutano/chip-atlas/blob/master/views/publications.markdown

# 連絡
  大田さんと畠中先生に連絡する
  
  
# Wabi データの整理、消去
  wabi              # <<=== コマンド (Mac)  w3oki アカウントにログイン
  table4wabiRequest # <<=== コマンド (Mac)  wabi へのリクエストを tsv 形式で整理する (table4wabiRequest.YYYYMMDD.tsv)
  tail -n+2 table4wabiRequest.YYYYMMDD.tsv | cut -c1-7| uniq -c # <<=== コマンド (Mac)  wabi へのリクエスト数を月毎に表示
  # deleteWabiResult  # <<=== コマンド (w3oki)  二週間前までのデータを消去

# スパコンの重要なファイルを iMac に保存
  backupDDBJ    # <<=== コマンド (iMac)  


# 不要な tmp ファイルや log を消去
rm Controller.sh.[eo][0-9][0-9]*
rm TimeCourse.sh.[eo][0-9][0-9]*
rm upDate.sh.[eo][0-9][0-9]*
rm upDate.sh.p[eo][0-9][0-9]*
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
rm paramListForColo.tab
rm -rf tmp/makeBigBed_log



=====================================================================================
# 部分解凍のしかた
mkdir backUp_ChIP-Atlas
cd backUp_ChIP-Atlas
tar xvjf ~/backUp_ChIP-Atlas.tar.bz2 "chipatlas/hoge/hage.bw" "chipatlas/foo/baa.bed" # 複数ファイル指定可能
tar xvjf ~/backUp_ChIP-Atlas.tar.bz2 "chipatlas/hoge" # ディレクトリ指定可能



=====================================================================================
# qchange 可能
upDate.sh (month 可)
metaDelete (month 可)
Controller (month 可)
TimeCourse (month 可)
srThg19 srTmm9 (month, esub 可)
libPrepFor (month 可)
classify.s (month 可) # 初期モード、-m "x" モードのみ
makeBigBed (month 可) # 初期モードのみ
bed4ToBed9
listForCla (month 可)
allPeaks_l (month 可)
targetGene
preProcess (month 可)
FF_Enhance
FF_Pr_hg19
FF_Pr_mm9
LD-DHS
GWAS (month 可)
iscGWAS (month 可)
hg19Prom (month 可)
mm9Prom (month 可)
R_fantomEn (month 不可)
R_FPmm9 (month 不可)
R_FPhg19 (month 不可)
webList (month 可)
trfB2w3 (month 可)


# qchange 不可能
coLocaliza # しかし、以下のようにメモリを大きく引き上げ、直接 submit するとなぜか OK。
           # qsub -l month -l medium -l s_vmem=64G -l mem_req=64G chipatlas/sh/coLocalization.sh chipatlas 12
           # もしくは qchange の第 3 引数を使っても良いかも
           # qchange coLocaliza month "-l s_vmem=64G -l mem_req=64G"
           
classify.s # qsub モードは不可
makeBigBed # qsub モードは不可


=====================================================================================
# CoLo の最中に update する。
  # 不要なファイルの消去
    rm Controller.sh.[eo][0-9][0-9]*
    rm TimeCourse.sh.[eo][0-9][0-9]*
    rm upDate.sh.[eo][0-9][0-9]*
    rm upDate.sh.p[eo][0-9][0-9]*
    rm classify.log.txt
    rm ncbi_error_report.xml
    rm timecourse.chipatlas.txt
    rm igv.log
    rm webList.sh.*
    rm -r ncbi
    rm CAUTION_makeBigBed.txt
    rm -rf tmp/makeBigBed_log
  # アップデート開始
    sh chipatlas/sh/upDate.sh  # <<=== コマンド (DDBJ) すぐに qsub されるので、どの mac でも可能

  # 全部 run が終わったら、コアダンプや異常終了をチェック
    sh chipatlas/sh/checkCoreDump.sh  # <<=== コマンド (DDBJ, 時間がかかるので、ラボの Mac で実行)
    
  # Curation のためのリストを作成。すぐに qsub になるので、どの Mac でも可能。
    sh chipatlas/sh/listForClassify.sh  # <<=== コマンド (DDBJ)
  
  # 古い classification のバックアップ、個別データの転送
    backUpOldList 201811  # <<=== コマンド (ラボのMac, スパコンでない。実行した月を入力)
    transferDDBJtoNBDC eachData  # <<=== コマンド (ラボのMac)  個別データを NBDC に転送。
                                 # 転送状況コマンド (ラボの Mac => nbdc =>): trfNBDC eachData.log

  # 機械学習による curation 予測 
    sh chipatlas/sh/ML_curation.sh initial  # <<=== コマンド (DDBJ) すぐに qsub されるので、どの mac でも可能。半日くらいかかる。
    
  # Curation の実行。
    chipatlas/classification を DL
    Google Refine > Undo / Redo > Apply にペースト
    Google Refine > Judge タブ > Facet > Custom text facet にペースト
    #!!! Curator のキャッシュを削除 !!!
        Safari > 環境設定 > プライバシー > Web サイトデータを管理 > "biosciencedbc.jp" を削除

  # Curation 終了後のチェック
    全てのファイルを tsv エクスポートし、Downloads/classification 配下に移動させる。
    以下のコマンドでチェック
    
      checkCuration  # <<=== コマンド (iMac)
  
    OK だったら、スパコンに Downloads/classification フォルダを chipatlas/ 配下にアップロード

  # 以降の assembled BEDの作成は CoLo が終了してから行う (sh chipatlas/sh/bed4ToBed9.sh から)
=====================================================================================

Awstats の取得
1) https://905945394038.signin.aws.amazon.com/console
2) サービス一覧から S3 を選択
3) chip-atlas-awstats-backup というバケットをクリック
4) 必要な .txt 形式のファイルをダウンロード
5) FileZilla を起動し、下記のとおり接続
   ホスト: ftp2013.biosciencedbc.jp
   ユーザー名: oki
   パスワード: #NShw16ni
   ポート: 21
6) 右下にある accesslog フォルダに .txt ファイルをアップロード
