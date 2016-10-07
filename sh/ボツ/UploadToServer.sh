#!/bin/sh
#$ -S /bin/sh

# qsub -o UploadToServer.log.txt -e UploadToServer.log.txt xhipome_ver3/sh/UploadToServer.sh xhipome_ver3
projectDir=$1
address=ftp2.biosciencedbc.jp
user=upload4
pass=S9wTgHyT

{
  echo "open -u $user,$pass $address"
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
