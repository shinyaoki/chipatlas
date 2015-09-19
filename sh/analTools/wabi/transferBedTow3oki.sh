#!/bin/sh
#$ -S /bin/sh

# sh chipatlas/sh/analTools/wabi/transferBedTow3oki.sh 

tmpDir=tmpDirFortransferBedTow3oki
rm -rf $tmpDir
mkdir -p $tmpDir/results
mkdir -p $tmpDir/lineNum

for Genome in `ls chipatlas/results/`; do
  mkdir -p $tmpDir/results/$Genome/public
  for bed in `echo chipatlas/results/$Genome/public/*.AllAg.AllCell.bed`; do
    outBed=$tmpDir/results/$Genome/public/`basename $bed`
    let i=$i+1
    # BED ファイルの整形、5000万行ごとに分割し、core dump を防ぐ
    echo "tail -n+2 $bed| tr '=;' '\t\t'| cut -f 1,2,3,5 > $outBed;\
          split -l 50000000 $outBed $outBed. ;\
          wc -l $outBed > $tmpDir/lineNum/$i;\
          rm $outBed"| qsub -N trfB2w3 -l short -o /dev/null -e /dev/null
  done
done

while :; do
  qN=`qstat| awk '$3 == "trfB2w3"'| wc -l`
  if [ "$qN" -eq 0 ]; then
    break
  fi
done

# BED ファイルの行数を集計。
cat $tmpDir/lineNum/*| tr ' /' '\t\t'| awk -F '\t' '
BEGIN {
  while ((getline < "chipatlas/lib/assembled_list/fileList.tab") > 0) {
    x[$1 ".bed",$2] = $2 "\t" $3 "\t" $5 "\t" $7
  }
} {
  print x[$6,$4] "\t" $1
}' > $tmpDir/lineNum.tsv

# NBDC サーバの lib フォルダに転送
nbdc
put tmpDirFortransferBedTow3oki/lineNum.tsv -o data/lib/lineNum.tsv

http://dbarchive.biosciencedbc.jp/kyushu-u/lib/lineNum.tsv



username="w3oki"
password="]xwCevL75"

expect -c "
set timeout 20
spawn su $username
expect \"パスワード:\"
send \"$password\n\"
send \"rm -r w3oki/chipatlas/results2\n\"
send \"cp -r $tmpDir/results w3oki/chipatlas/results2\n\"
interact
"
rm -r $tmpDir/lineNum
mv $tmpDir chipatlas/sh/analTools/wabi/dirFortransferBedTow3oki