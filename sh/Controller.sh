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
intT=1800
HDsize=`cat $projectDir/sh/preferences.txt |awk -F '\t' '{if ($1 == "HDsize") printf "%s", $2}'`
let HDsize=$HDsize-2


qsub $projectDir/sh/TimeCourse.sh $projectDir "$GENOME"

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
    if ($11 ~  "Illumina")\
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
      nQ=`qstat|tail -n +3| awk '{print $5}'|cut -c1|grep -cv -e "r"` # state が qw または t の数
      curT=`date +%s`
      let difT=$curT-$prevT
      
      if [ $difT -gt $intT ]; then
        prevT=$curT
        Sz=`du -s --block-size=1T|cut -f1`
        if [ $Sz -lt $HDsize ]; then # HDD 容量が 18 TB 以下の時は、次回の du は 30 分後、それ以上の時は 100 秒後
          intT=1800
          let Dif=$HDsize-$Sz
          if [ $Dif -gt 10 ]; then  # HDD 残量が 10 TB 以上の時は、次回の du は 3 時間後
            intT=10800
          fi
        else
          intT=100
        fi
      fi
      
      if [ $nQ -le 10 -a $Sz -lt $HDsize ]; then # ジョブ待ち数が 11 以下で、HDD 容量が 18 TB 以下の時に submit する
#        short=`sh $projectDir/sh/QSUB.sh shortOrweek`
        qsub -N "srT$Genome" -o $Logfile -e $Logfile -pe def_slot $nslot $short $projectDir/sh/sraTailor.sh $SRX $Genome $projectDir "$QVAL"
        sleep 1
        break
      fi
    done
  done
done
exit

# 計算がエラーになる場合
#                   qstat     SRXディレクトリ     Bed/BigWig     log        summary      例
# (1) コアダンンプ    残らず     残る               できない        できる      できない      SRX328589 (hg19)
# (2) aspera エラー  残る       残る               できない        できる      できない      混雑状況によるため再現できない -> 再投入が必要
# (3) MACS2 エラー   残らず     残らず              できない        できる      できる       SRX211437 (sacCer3)

# Aspera エラーの場合の再投入

projectDir=chipatlas
Genome=hg19
nslot="8-16"

for SRX in SRX100439  SRX100442  SRX190188  SRX193600  SRX328589  SRX328591  SRX610813  SRX610814; do
  QVAL="05 10 20"
  Logfile="$projectDir/results/$Genome/log/$SRX.log.txt"
  
  rm -f $Logfile
  rm -rf $projectDir/results/$Genome/$SRX
  
  qsub -N "srT$Genome" -o $Logfile -e $Logfile -pe def_slot $nslot $projectDir/sh/sraTailor.sh $SRX $Genome $projectDir "$QVAL"
done


projectDir=chipatlas
Genome=mm9
nslot="8-16"
for SRX in DRX012091 DRX012092 DRX012093 DRX012094 DRX012095 ERX132886 SRX258122 SRX338012 SRX472712 SRX500192 SRX500194 SRX849410 SRX849411 SRX849412 SRX849413 SRX849414 SRX849415 SRX849416 SRX849417 SRX849418 SRX849419 SRX849420 SRX849421 SRX849422 SRX849423 SRX849424 SRX849425 SRX849426 SRX849427 SRX849428 SRX849429 SRX849430 SRX849431 SRX849432 SRX849433 SRX849434 SRX849435 SRX849436 SRX849437 SRX849438 SRX849439 SRX849440 SRX849441; do
  QVAL="05 10 20"
  Logfile="$projectDir/results/$Genome/log/$SRX.log.txt"
  
  rm -f $Logfile
  rm -rf $projectDir/results/$Genome/$SRX
  
  qsub -N "srT$Genome" -o $Logfile -e $Logfile -pe def_slot $nslot $projectDir/sh/sraTailor.sh $SRX $Genome $projectDir "$QVAL"
done


SRX849410 SRX849411 SRX849412 SRX849413 SRX849415 SRX849416 SRX849417 SRX849418 SRX849419 SRX849420 SRX849421 SRX849422 SRX849423 SRX849424 SRX849425 SRX849426 SRX849427 SRX849428 SRX849429 SRX849431 SRX849433 SRX849435 SRX849436 SRX849437 SRX849438 SRX849439 SRX849440 SRX849441

