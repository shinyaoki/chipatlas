#!/bin/sh
#$ -S /bin/sh

# sh chipatlas/sh/checkCoreDump.sh

projectDir=`echo $0| sed 's[/sh/checkCoreDump.sh[['`

echo "残存フォルダの終了状態を調べています..."
echo ""
for Genome in `ls $projectDir/results`; do
  for SRX in `ls $projectDir/results/$Genome| grep '[SDE]RX[0-9][0-9][0-9][0-9]'`; do
    ls $projectDir/results/$Genome/$SRX| grep -c "core\."| awk -v Genome=$Genome -v SRX=$SRX '{
      printf "%s\t%s\t%s\n", Genome, SRX, ($1 > 0) ? "Core dump" : "Unknown"
    }'
  done
done


echo ""
echo "通信障害やメモリ不足による異常終了を調べています..."
echo ""

for genome in `ls $projectDir/results`; do
  awk -F '\t' -v projectDir=$projectDir -v genome=$genome '{
    if ($3 + 0 == 0) {
      x = 0
      Log = projectDir "/results/" genome "/log/" $1 ".log.txt"
      while ((getline < Log) > 0) {
        if ($0 ~ "Completed: 0K bytes transferred") x++
        if ($0 ~ "Server aborted session: No such file or directory") x++
        if ($0 ~ "ncbi_error_report.xml") x++
        if ($0 ~ "Stale file handle") x++
        if ($0 ~ "_1.fq: そのようなファイルやディレクトリはありません") x++
      }
      close(Log)
      if (x == 0) {
        i++
        N = split(FILENAME, a, "/")
        sub(".txt", "", a[N])
        srx = srx " " a[N]
      }
    }
  } END {
    printf "%s\t%d\t%s\n", genome, i, srx
  }' $projectDir/results/$genome/summary/*RX*.txt
done| awk -F '\t' '{
  printf "%s\t%d 件%s\n", $1, $2, $3
  j += $2
} END {
  if (j > 0) {
    print "\n再実行の必要があるため、以下を実行してください。"
    print "qsub -o /dev/null -e /dev/null chipatlas/sh/reRunSraTailor.sh chipatlas"
  } else {
    print "\n再実行の必要はないので、以下を実行してください。"
    print "sh chipatlas/sh/listForClassify.sh"
  }
}'
