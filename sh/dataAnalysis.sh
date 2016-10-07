#!/bin/sh
#$ -S /bin/sh

# sh chipatlas/sh/dataAnalysis.sh                                            # 初期モード
# qsub -o /dev/null -e /dev/null chipatlas/sh/dataAnalysis.sh -l chipatlas   # qsub モード

Type=0
while getopts l option; do
  case "$option" in
    l) Type="1";;
  esac
done
shift `expr $OPTIND - 1`

####################################################################################################################################
#                                                         初期 モード
####################################################################################################################################
if [ $Type = "0" ]; then
  projectDir=`echo $0| sed 's[/sh/dataAnalysis.sh[['`
  rm -rf makeBigBed_log
  
  sh $projectDir/sh/dataNumbers.sh $projectDir                                 # データ数を集計し、グラフを作成
  sh $projectDir/sh/coLocalization.sh INITIAL $projectDir                      # colo の実行 (18 日, 2016/09/09)
  sh $projectDir/sh/targetGenes.sh INITIAL $projectDir                         # targetGenes の実行 (1 時間弱, 2016/05/26)
  sh $projectDir/sh/analTools/wabi/transferBedTow3oki.sh $projectDir           # in silico ChIP 用の BED ファイルを作成、w3oki へ転送 (2 時間弱, 2016/05/26)
  rm -rf $projectDir/lib/inSilicoChIP
  mv tmpDirFortransferBedTow3oki $projectDir/lib/inSilicoChIP
  qsub -o /dev/null -e /dev/null $projectDir/sh/analTools/preProcessed_insilicoChIP.sh initial   # GWAS, FANTOM データの in silico ChIP (６時間, 2016/05/26)
  qsub -o /dev/null -e /dev/null -l month -l medium $projectDir/sh/dataAnalysis.sh -l $projectDir   # analysisList.tab の作成
  exit
fi

####################################################################################################################################
#                                                         qsub モード
####################################################################################################################################
projectDir=$1

# colo と targetGenes が終わるまで待つ。
while :; do
  qNum=$(qstat| awk '{
    if ($3 == "coLocaliza" || $3 == "targetGene" || $3 == "trfB2w3") i++
  } END {
    printf "%s", (i > 0)? 1 : 0
  }')
  if [ $qNum = "0" ]; then
    break
  fi
  sleep 60
done


# analysisList.tab の作成
for Genome in `ls $projectDir/results`; do
  ls $projectDir/results/$Genome/colo| grep ^"STRING_"| grep ".html"$| sed 's/STRING_//'| tr '.' '\t'| cut -f1-2| sort| uniq > tmpFileForColoList
  ls $projectDir/results/$Genome/targetGenes| grep ^"STRING_"| grep ".html"$| sed 's/STRING_//'| tr '.' '\t'| cut -f1| sort| uniq > tmpFileFortargetGenesList
    
  cat tmpFileForColoList tmpFileFortargetGenesList| cut -f1| sort| uniq| awk -F '\t' -v Genome=$Genome '
  BEGIN {
    while ((getline < "tmpFileForColoList") > 0)        gColo[$1] = gColo[$1] "," $2   # g["POU5F1"] = ,Epidermis,Pluripotent_stem_cell
    for (key in gColo) {
      sub(",", "", gColo[key])
      gsub("_", " ", gColo[key])
    }
    while ((getline < "tmpFileFortargetGenesList") > 0) gTarg[$1] = 1        # g["POU5F1"] = 1
  } {
    if (!gColo[$1]) gColo[$1] = "-"
    if (gTarg[$1] == 1) Targ = "+"
    else                Targ = "-"
    print $1 "\t" gColo[$1] "\t" Targ "\t" Genome
  }'
done > $projectDir/lib/assembled_list/analysisList.tab
rm tmpFileForColoList tmpFileFortargetGenesList

bin/alertFromDDBJ "ChIP-Atlas アラート" "dataAnalysis.sh 完了"

# $1 = 抗原小
# $2 = 細胞大 (Colo 用、コンマ区切り、ない場合は "-")
# $3 = Target gene の有無 ("+" or "-") hg19 ZNF3 は例外的にナシ。ピーク数が少なく、どの TSS の近くにもないためか。
# $4 = Genome
# ファイル名
# Colo : $1.gsub(" ", "_", $2).html
# Target : $1.html


