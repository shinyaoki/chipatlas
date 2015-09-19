#!/bin/sh
#$ -S /bin/sh
splitFn=$1
projectDir=$2


for SRX in `cat $splitFn`; do
  for Genome in `ls $projectDir/results/`; do
    rm $projectDir/results/$Genome/BigWig/$SRX.bw
    rm $projectDir/results/$Genome/log/$SRX.log.txt
    rm $projectDir/results/$Genome/metadata/$SRX.meta.txt
    rm $projectDir/results/$Genome/summary/$SRX.txt

    for qVal in `ls $projectDir/results/$Genome/| grep Bed| cut -c 4-`; do
      rm $projectDir/results/$Genome/Bed$qVal/Bed/$SRX.$qVal.bed
      rm $projectDir/results/$Genome/Bed$qVal/BigBed/$SRX.$qVal.bb
    done
  done
done

