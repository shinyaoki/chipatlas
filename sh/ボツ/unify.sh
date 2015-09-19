#!/bin/sh
#$ -S /bin/sh
# BED4 ファイルを BED9 形式にする
# 実行例 sh $projectDir/sh/unify.sh

projectDir=`echo $0| sed 's[/sh/unify.sh[['`
GENOME=`ls $projectDir/results/| tr '\n' ' '`



      # $1 = SRX
      # $2 = SRA
      # $3 = フルタイトル
      # $4 = 短縮タイトル (50 字以内)
      # $5 = 抗原抗体
      # $6 = 短縮 抗原抗体
      # $7 = 細胞組織
      # $8 = 短縮 細胞組織
      # $9 = ChIP-Seq or DNase-Hypersensitivity
# cat xhipome_ver3/results/hg19/tag/SRX381321.tag.txt


for Genome in `echo $GENOME`; do
  cat $projectDir/results/$Genome/tag/*.tag.txt > $projectDir/results/$Genome/tag/tmp.tag.txt
  
  cat xhipome_ver3/results/hg19/tag/SRX381321.tag.txt| awk -v ProjDir=$projectDir -v GENOME=$Genome '
  BEGIN {
    while ((getline var < ProjDir"/results/"GENOME"/classification/ag_Index."GENOME".tab") > 0) {
      split(var, antg, "\t")
      sub(" ", "", antg[2])
      gsub(" ", "_", antg[2])
      UniAntg[antg[1]] = antg[2] # UniAntg["Pol2"] = RNA_plymerase_II
    }
    close(ProjDir"/results/"GENOME"/classification/ag_Index."GENOME".tab")
    while ((getline var < ProjDir"/results/"GENOME"/classification/ct_Index."GENOME".tab") > 0) {
      split(var, cell, "\t")
      gsub(" ", "_", cell[2])
      UniCell[cell[1]] = cell[2] # UniCell["hES_Cells"] = Embryonic_stem_cells_(and_EC_cells)
    }
    close(ProjDir"/results/"GENOME"/classification/ct_Index."GENOME".tab")
  } {
    UA = $6
    UC = $8
    for (OriAntg in UniAntg) if ($5 == OriAntg) UA = UniAntg[OriAntg]
    for (OriCell in UniCell) if ($7 == OriCell) UC = UniCell[OriCell]
    print $0 "\t" UA "\t" UC > ProjDir"/results/"GENOME"/tag/"$1".tag.txt"
  }'
  rm $projectDir/results/$Genome/tag/tmp.tag.txt
done
exit







RR=0
ctn=0
Type=all

while getopts r: option
do
  case "$option" in
  r)
    RR="$OPTARG"
    if [ $RR = "A" ]; then    # remove オプション (-r A: 全て)
      Type=all
    elif [ $RR = "H" ]; then    # remove オプション (-r H: ヒストン除去)
      Type=woH
    elif [ $RR = "T" ]; then  # remove オプション (-r T: ヒストンのみ)
      Type=His
    elif [ $RR = "D" ]; then  # remove オプション (-r D: DNase-seq のみ)
      Type=DHS
    fi
    ;;
  esac
done

# オプション解析終了後に不要となったオプション部分を shift コマンドで切り捨てる
shift `expr $OPTIND - 1`

####################################################################################################################################
#                                                             初期モード
####################################################################################################################################
if [ $RR = "0" ]; then
  projectDir=`echo $0| sed 's[/sh/bed4ToBigBed9.sh[['`
  GENOME=`ls $projectDir/results/| tr '\n' ' '`
  QVAL=$(ls $projectDir/results/`ls $projectDir/results/| head -n1`| grep Bed| cut -c 4-| tr '\n' ' ')

