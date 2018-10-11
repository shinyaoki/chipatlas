#!/bin/sh
#$ -S /bin/sh
splitFn=$1
projectDir=$2
GENOME=`ls $projectDir/results/`
QVAL=`cat $projectDir/sh/preferences.txt| awk -F '\t' '$1 == "qVal" {print $2}'`

cat $splitFn| while read SRX; do
  for Genome in $GENOME; do
    rm $projectDir/results/$Genome/BigWig/$SRX.bw
    rm $projectDir/results/$Genome/log/$SRX.log.txt
    rm $projectDir/results/$Genome/metadata/$SRX.meta.txt
    rm $projectDir/results/$Genome/summary/$SRX.txt

    for qVal in $QVAL; do
      rm $projectDir/results/$Genome/Bed$qVal/Bed/$SRX.$qVal.bed
      rm $projectDir/results/$Genome/Bed$qVal/BigBed/$SRX.$qVal.bb
    done
  done
done
