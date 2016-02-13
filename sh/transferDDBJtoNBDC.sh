#!/bin/sh
#$ -S /bin/sh

# sh chipatlas/sh/transferDDBJtoNBDC.sh eachData
# sh chipatlas/sh/transferDDBJtoNBDC.sh assemble
# sh chipatlas/sh/transferDDBJtoNBDC.sh analysed
# qsub chipatlas/sh/transferDDBJtoNBDC.sh QSUB $projectDir $fn $qn

Type=$1
eval `cat bin/nbdc| grep "="`

if [ "$Type" != "QSUB" ]; then
#####################################################################################
#                                     初期モード                                     #
#####################################################################################
  projectDir=`echo $0| sed 's[/sh/transferDDBJtoNBDC.sh[['`
  fn="UploadToServer_""$Type"
  qn="$Type"TF
  
  {
    echo "open -u $user,$pass $address"
    echo "set net:limit-total-rate 31457280"
  
    case $Type in
      "eachData" )
        for Genome in `ls $projectDir/results`; do
          echo "echo == $Genome BigWig =="
          echo "mirror -R --delete --verbose=3 --parallel=8 $projectDir/results/$Genome/BigWig data/$Genome/eachData/bw"
          for qVal in `ls $projectDir/results/$Genome/| grep Bed| cut -c4-`; do
            echo "echo == $Genome BigBed $qVal =="
            echo "mirror -R --delete --verbose=3 --parallel=8 $projectDir/results/$Genome/Bed$qVal/BigBed data/$Genome/eachData/bb$qVal"
            echo "echo == $Genome Bed $qVal =="
            echo "mirror -R --delete --verbose=3 --parallel=8 $projectDir/results/$Genome/Bed$qVal/Bed data/$Genome/eachData/bed$qVal"
          done
        done
      ;;
      "assemble" )
        for Genome in `ls $projectDir/results`; do
          echo "echo == $Genome assembled =="
          echo "mkdir data/$Genome/assembled_new"
          echo "mirror -R --verbose=3 --parallel=8 $projectDir/results/$Genome/public data/$Genome/assembled_new"
        done
      ;;
      "analysed" )
        echo "echo == assembled_list =="
        echo "put -c $projectDir/lib/inSilicoChIP/lineNum.tsv -o data/util/lineNum.tsv"
        echo "mirror -R --delete --verbose=3 --parallel=8 $projectDir/lib/assembled_list data/metadata"
        echo "put -c $projectDir/sh/ag_attributes.txt -o data/metadata/ag_attributes.txt"
        echo "put -c $projectDir/sh/ct_attributes.txt -o data/metadata/ct_attributes.txt"
        for Genome in `ls $projectDir/results`; do
          echo "echo == $Genome colo =="
          echo "mirror -R --delete --verbose=3 --parallel=8 $projectDir/results/$Genome/colo data/$Genome/colo"
          echo "echo == $Genome target =="
          echo "mirror -R --delete --verbose=3 --parallel=8 $projectDir/results/$Genome/targetGenes data/$Genome/target"
        done
      ;;
    esac
  } > $fn.lftp
  rm -f $fn.log
  qsub -o $fn.log -e $fn.log -N $qn $projectDir/sh/transferDDBJtoNBDC.sh QSUB $projectDir $fn $qn
else
#####################################################################################
#                                     qsub モード                                    #
#####################################################################################
  projectDir=$2
  fn=$3
  qn=$4
  while :; do
    echo $fn $qn
    lftp -f $fn.lftp
    echo "finished"
    Nerror=`cat $fn.log| grep -c -e "gnutls_record_recv" -e "Login incorrect"`
    if [ "$Nerror" = "0" ]; then
      break
    fi
    : > $fn.log
  done
  
  if [ "$qn" = "assembleTF" ]; then
    {
      echo "open -u $user,$pass $address"
      echo "mkdir data/assembled_old"
      for Genome in `ls $projectDir/results`; do
        echo "echo Moving $Genome assembled directory."
        echo "mv data/$Genome/assembled data/assembled_old/$Genome"
        echo "mv data/$Genome/assembled_new data/$Genome/assembled"
      done
      echo "echo Removing assembled_old directiory..."
      echo "rm -r data/assembled_old"
      echo "echo Finished"
    } > $fn.lftp
    lftp -f $fn.lftp
  fi
fi

exit

Login incorrect


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
