#!/bin/sh
#$ -S /bin/sh

# --------------------------------
# $1 projectDir (例 chipome_ver3)
# $2 ゲノム (例 "hg19 mm9 ce10 dm3 sacCer3")

# qsub $projectDir/sh/TimeCourse.sh $projectDir "$GENOME"
# --------------------------------

projectDir=$1
GENOME="$2"

T=60
iniT=`date +%s`
while :; do
  curT=`date +%s`
  let pasT=$curT-$iniT
  Tera=`du -s --block-size=1G|awk '{printf "%.2f", $1/1000}'`
  echo -en "$pasT\t$Tera"

  for Genome in `echo $GENOME`; do
    submit=`qstat|grep srT| awk '{if ($5 == "r") print}'| grep -c $Genome`
    finish=`ls $projectDir/results/$Genome/summary|wc -l`
    echo -en "\t$submit\t$finish"
  done
  echo ""
  sleep $T
  
done >> timecourse.$1.txt
