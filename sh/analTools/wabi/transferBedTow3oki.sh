#!/bin/sh
#$ -S /bin/sh

# sh chipatlas/sh/analTools/wabi/transferBedTow3oki.sh chipatlas
projectDir=$1
tmpDir=tmpDirFortransferBedTow3oki

ql=`sh chipatlas/sh/QSUB.sh mem`
for Genome in `ls $projectDir/results/`; do
  mkdir -p $tmpDir/results/$Genome/public
  for bed in `echo $projectDir/results/$Genome/public/*.AllAg.AllCell.bed`; do
    outBed=$tmpDir/results/$Genome/public/`basename $bed`
    let i=$i+1
    # BED ファイルの整形、5000万行ごとに分割し、core dump を防ぐ
    
    cat << 'DDD' > $tmpDir/sh/$i
#!/bin/sh
#$ -S /bin/sh
DDD
    cat << DDD >> $tmpDir/sh/$i
      split -l 50000000 $outBed $outBed.
      wc -l $outBed > $tmpDir/lineNum/$i
      rm $outBed
DDD
    qsub -N trfB2w3 $ql -o /dev/null -e /dev/null $tmpDir/sh/$i
  done
done


while :; do
  qN=`qstat| awk '$3 == "trfB2w3"'| wc -l`
  if [ "$qN" -eq 0 ]; then
    rm -r $tmpDir/sh
    break
  else
    echo "Waiting for converting Bed files..."
    date
    sleep 60
  fi
done

# BED ファイルの行数を集計。
fileList="$projectDir/lib/assembled_list/fileList.tab"
cat $tmpDir/lineNum/*| tr ' /' '\t\t'| awk -F '\t' -v fileList=$fileList '
BEGIN {
  while ((getline < fileList) > 0) {
    x[$1 ".bed",$2] = $2 "\t" $3 "\t" $5 "\t" $7
  }
} {
  print x[$6,$4] "\t" $1
}' > $tmpDir/lineNum.tsv


## w3oki アカウントに Bed ファイルをコピー
# w3oki のパスワード取得
eval `cat bin/w3oki| grep -e "username=" -e "password="`

# w3oki で実行するためのコマンド
cmnd=$(echo -e '
  rm -rf w3oki/tmpDirFortransferBedTow3oki
  for genome in `ls tmpDirFortransferBedTow3oki/results/`; do
    dirOkiS="tmpDirFortransferBedTow3oki/results/$genome/public"        # okishinya アカウントの public フォルダ
    dirWab1="w3oki/tmpDirFortransferBedTow3oki/results/$genome/public"  # w3oki アカウントの 一時的 public フォルダ
    dirWab2="w3oki/chipatlas/results/$genome/public"                    # w3oki アカウントの 計算用 public フォルダ
    mkdir -p w3oki/tmpDirFortransferBedTow3oki/results/$genome
    echo okishinya から w3oki へ $genome の BED ファイルを転送中...
    cp -r "$dirOkiS" "$dirWab1"
    mv "$dirWab2" "$dirWab2"_old
    mv "$dirWab1" "$dirWab2"
    rm -r "$dirWab2"_old
  done
  
  cp -r chipatlas/lib/TSS w3oki/chipatlas/lib/
  cp -f chipatlas/lib/assembled_list/experimentList.tab w3oki/chipatlas/lib/assembled_list/experimentList.tab
  cp -f chipatlas/lib/assembled_list/fileList.tab w3oki/chipatlas/lib/assembled_list/fileList.tab
  rm -r w3oki/tmpDirFortransferBedTow3oki
  exit
'| awk '{
  gsub("\"", "\\\"", $0)    # ダブルクォートと $ の前にバックスラッシュをつける
  gsub("\\$", "\\\$", $0)
  print
}') #"

# expect でコマンド実行
expect -c "
  set timeout 20
  spawn su $username
  expect \"パスワード:\"
  send \"$password\n\"
  expect \"\$\"
  send \"
    $cmnd
  \"
  interact
"
