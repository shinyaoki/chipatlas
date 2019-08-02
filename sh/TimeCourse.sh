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
  pasT=`echo $curT $iniT| awk '{printf ($1 - $2) / 3600}'`
  Tera=$(lfs quota -u `pwd -P| cut -d/ -f5` /`pwd -P| cut -d/ -f2`| tail -n1| awk '{printf "%.2f", $2/1000000000}')
  echo -en "$pasT\t$Tera"

  for Genome in `echo $GENOME`; do
    submit=`qstat|grep srT| awk '{if ($5 == "r") print}'| grep -c $Genome`
    finish=`ls $projectDir/results/$Genome/summary| wc -l`
    echo -en "\t$submit\t$finish"
  done
  echo ""
  sleep $T
  
done >> timecourse.$1.tsv
