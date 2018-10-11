#!/bin/sh
#$ -S /bin/sh

# --------------------------------
# $1 ゲノム (例 "hg19 mm9 ce10 dm3 sacCer3")
# $2 projectDir (例 chipome_ver3)
# $3 qVal (例 "05 10 20")
# $4 メタデータ (例 NCBI_SRA_Metadata_Full_20150101.metadata.tab)

# qsub $projectDir/sh/Controller.sh "hg19 mm9 ce10 dm3 sacCer3" $projectDir "05 10 20" $projectDir/lib/metadata/$MetadataFullDir.metadata.tab
# --------------------------------
GENOME="$1"
projectDir=$2
QVAL="$3"
metaData=$4
nslot=`cat $projectDir/sh/preferences.txt |awk -F '\t' '{if ($1 == "nSlotForSrT") printf "%s", $2}'`
Sz=0
prevT=`date +%s`
intT=21600
HDsize=$(lfs quota -u `pwd -P| cut -d/ -f4` /`pwd -P| cut -d/ -f2`| tail -n1| awk '{printf "%d", $4/1000000000}')
let HDsize=$HDsize-2


qsub -l d_rt=1440:00:00 -l s_rt=1440:00:00 $projectDir/sh/TimeCourse.sh $projectDir "$GENOME"
qsub -l d_rt=1440:00:00 -l s_rt=1440:00:00 -o libPrepForAnal.log.txt -e libPrepForAnal.log.txt -pe def_slot 4 $projectDir/sh/libPrepForAnal.sh $projectDir # Colo や Target のためのライブラリ


for Genome in `echo $GENOME`; do
  # Organism Name の取得
  Org=`cat $projectDir/sh/preferences.txt |awk -F '\t' -v G=$Genome '{
    if ($1 == "Genome") {
      split($2, all, " ")
      for (key in all) {
        split (all[key], arr, "=")
        if (arr[1] == G) {
          gsub ("_", " ", arr[2])
          printf "%s", arr[2]
        }
      }
    }
  }'`

  # ラン用のメタデータを作製
  cat $metaData | awk -v ORG="$Org" -F '\t' '{
    if ($4  == "ChIP-Seq" || $4  == "DNase-Hypersensitivity")\
    if ($5  == "GENOMIC")\
    if ($6  == "ChIP" || $6  == "DNase")\
    if ($11 ~  "Illumina" || $11 ~  "NextSeq" || $11 ~  "HiSeq")\
    if ($17 ~  ORG)\
      print
  }' > $projectDir/results/$Genome/metadataForRun.txt
done
    # cellTissueList/$i.tab の例 ($1 数、$2 SRX、$3 細胞組織名、$4 略称)
    #    113 SRX319846       Primary_thioglycollate-elicited_peritoneal_macrophages  Primary_thioglycollate...
    #     96 SRX020259       Liver_tissue    Liver_tissue


  
# ここから本番
for Genome in `echo $GENOME`; do
  for SRX in `cat $projectDir/results/$Genome/metadataForRun.txt| cut -f1`; do
    Logfile="$projectDir/results/$Genome/log/$SRX.log.txt"
    awk -v Srx=$SRX '{if ($1 == Srx) print}' $projectDir/results/$Genome/metadataForRun.txt > $projectDir/results/$Genome/metadata/$SRX.meta.txt
    
    while :; do
      nW=`cat chipatlas/sh/preferences.txt| awk '$1 == "JOB_NUM_4_wait" {printf $2}'` # ジョブ待ち数
      nQ=`qstat|tail -n +3| awk '$3 ~ "srT" && $5 !~ /r$/ {i++} END {printf "%d", i}'` # state が qw または t の数
      curT=`date +%s`
      let difT=$curT-$prevT
      
      if [ $difT -gt $intT ]; then
        prevT=$curT
        Sz=$(lfs quota -u `pwd -P| cut -d/ -f4` /`pwd -P| cut -d/ -f2`| tail -n1| awk '{printf "%d", $2/1000000000}')
        if [ $Sz -lt $HDsize ]; then # HDD 空き容量が 2 TB 以上の時は、次回の計測は 3 分後、それ以下の時は 100 秒後
          intT=180
          let Dif=$HDsize-$Sz
          if [ $Dif -gt 10 ]; then  # HDD 残量が 10 TB 以上の時は、次回の計測は 6 時間後
            intT=21600
          fi
        else
          intT=100
        fi
      fi
      
      if [ $nQ -le $nW -a $Sz -lt $HDsize ]; then # ジョブ待ち数が 11 以下で、HDD 空き容量が 2 TB 以上の時に submit する
        ql=`sh $projectDir/sh/QSUB.sh mem`
        qsub $ql -N "srT$Genome" -o $Logfile -e $Logfile -pe def_slot $nslot $projectDir/sh/sraTailor.sh $SRX $Genome $projectDir "$QVAL"
        sleep 1
        break
      fi
    done
  done
done
exit

# 計算がエラーになる場合
#                     qstat     SRXディレクトリ     Bed/BigWig     log        summary      例
# (1) コアダンンプ      残らず     残る               できない        できる      できない      SRX328589 (hg19)
# (2) aspera エラー    残る       残る               できない        できる      できない      混雑状況によるため再現できない -> 再投入が必要
# (3) MACS2 エラー     残らず     残らず              できない        できる      できる       SRX211437 (sacCer3)
# (4) 時間切れ         残らず     残る                できない        できる      できない      SRX716883 (mm9)
# (5) MACS メモリ不足  残らず     残る                できる         できる       できない      DRX048524 (hg19)

# Aspera エラーの場合の再投入

projectDir=chipatlas
Genome=mm9
nslot="8-64"

for SRX in SRX814801 SRX810565 SRX258122 SRX1098159 SRX1098158 SRX1098157 SRX1098156; do
  QVAL="05 10 20"
  Logfile="$projectDir/results/$Genome/log/$SRX.log.txt"
  
  rm -f $Logfile
  rm -rf $projectDir/results/$Genome/$SRX
  
  qsub -N "srT$Genome" -o $Logfile -e $Logfile -pe def_slot $nslot -l month -l medium $projectDir/sh/sraTailor.sh $SRX $Genome $projectDir "$QVAL"
done


projectDir=chipatlas
Genome=rn6
nslot="8-64"
for SRX in SRX1776226; do
  QVAL="05 10 20"
  Logfile="$projectDir/results/$Genome/log/$SRX.log.txt"
  
  rm -f $Logfile
  rm -rf $projectDir/results/$Genome/$SRX
  
  qsub -N "srT$Genome" -o $Logfile -e $Logfile -pe def_slot $nslot -l month -l medium -l s_vmem=128G -l mem_req=128G $projectDir/sh/sraTailor.sh $SRX $Genome $projectDir "$QVAL"
done

chipatlas/results/mm9/SRX814801:
chipatlas/results/mm9/SRX810565:
chipatlas/results/mm9/SRX258122:
chipatlas/results/mm9/SRX1098159:
chipatlas/results/mm9/SRX1098158:
chipatlas/results/mm9/SRX1098157:
chipatlas/results/mm9/SRX1098156:
chipatlas/results/hg19/SRX100439:
SRX814801 SRX810565 SRX258122 SRX1098159 SRX1098158 SRX1098157 SRX1098156