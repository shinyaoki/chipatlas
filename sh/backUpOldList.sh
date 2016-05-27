#!/bin/sh
#$ -S /bin/sh

# sh chipatlas/sh/backUpOldList.sh 201509

Date=$1
projectDir=`echo $0| sed 's[/sh/backUpOldList.sh[['`

eval `cat bin/nbdc| grep "="`  # NBDC のパスワードなどを取得
cat << EOS | lftp
  open -u $user,$pass $address
  set net:limit-total-rate 31457280
  mkdir data/history/$Date
  mkdir data/history/$Date/classification
  mirror -R --verbose=3 --parallel=1 $projectDir/classification data/history/$Date/classification
  get data/util/lineNum.tsv 
  put lineNum.tsv -o data/history/$Date/lineNum.tsv
  put $projectDir/lib/assembled_list/analysisList.tab -o data/history/$Date/analysisList.tab
  put $projectDir/lib/assembled_list/experimentList.tab -o data/history/$Date/experimentList.tab
  put $projectDir/lib/assembled_list/fileList.tab -o data/history/$Date/fileList.tab
EOS
