#!/bin/sh
#$ -S /bin/sh

# qsub -o /dev/null -e /dev/null chipatlas/sh/allPeaks_light.sh "chipatlas/results/hg19/public/ALL.ALL.10.AllAg.AllCell"

inBn="$1"
projectDir=`echo $inBn| cut -d '/' -f1`
genome=`echo $inBn| cut -d '/' -f3`
bed="$inBn".bed
qVal=`basename "$inBn"| cut -d '.' -f3`
bn=`basename "$inBn"`
mkdir -p "$projectDir/results/$genome/allPeaks_light"
outLight="$projectDir/results/$genome/allPeaks_light/$bn.bed"

tmpDir=tmpDirFortransferBedTow3oki
mkdir -p $tmpDir/results/$genome/public
tail -n+2 "$bed"| awk -F '\t' -v OFS='\t' '{
  sub("=", "\t", $4)
  sub(";", "\t", $4)
  print $0
}'| cut -f1-3,5,7| tee "$outLight"| cut -f1-4 > $tmpDir/results/$genome/public/$bn.bed  # in silico ChIP 用のファイル作成

N=`echo $bn| grep -c "ALL.ALL."`  # もし BED が ALL.ALL. で始まる場合、ダウンロード用の gz ファイルを作成する
if [ "$N" -eq 1 ]; then
  cat "$outLight"| gzip - > $projectDir/results/$genome/allPeaks_light/allPeaks_light.$genome.$qVal.bed.gz
fi
rm "$outLight"

