#!/bin/sh
#$ -S /bin/sh

# qsub -o transferDDBJtoNBDC.log -e transferDDBJtoNBDC.log chipatlas/sh/transferDDBJtoNBDC.sh chipatlas
projectDir=$1
data="/mnt/nfs1/archive/kyushu/data"

# NBDC の address, user, pass を変数定義
eval `cat bin/nbdc| grep "="`



{
  echo "open -u $user,$pass $address"
  for Genome in `ls $projectDir/results`; do


nbdc
mkdir data2
set net:limit-total-rate 31457280
mirror -R --parallel=1000 -I "public/*.bed" -I "public/*.bed.idx" chipatlas/results data2



総入れ替え
data/$Genome/assembled/
  .bed
  .bed.idx
data/$Genome/colo/
  .html
  .tsv
  .gml
data/$Genome/target/
  .html
  .tsv

同期
data/$Genome/eachData/


{
  echo "open -u $user,$pass $address"
  echo "mkdir data2"
  
  
  for Genome in `ls $projectDir/results`; do
    cat << EOS
      mkdir data/$Genome
      mkdir data/$Genome/assembled
      mkdir data/$Genome/eachData
      mkdir data/$Genome/eachData/bw
      mirror -R --delete --verbose=3 --parallel=8 $projectDir/results/$Genome/BigWig data/$Genome/eachData/bw
      mirror -R --delete --verbose=3 --parallel=8 $projectDir/results/$Genome/public data/$Genome/assembled
EOS
    for qVal in `ls $projectDir/results/$Genome/| grep Bed| cut -c4-`; do
      cat << EOS
        mkdir data/$Genome/eachData/bb$qVal
        mirror -R --delete --verbose=3 --parallel=8 $projectDir/results/$Genome/Bed$qVal/BigBed data/$Genome/eachData/bb$qVal
EOS
    done
  done
} > UploadToServer.fltp

lftp -f UploadToServer.fltp

