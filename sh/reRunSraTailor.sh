#!/bin/sh
#$ -S /bin/sh

# qsub -o /dev/null -e /dev/null chipatlas/sh/reRunSraTailor.sh chipatlas

projectDir=$1
nslot="4-16"
QVAL="05 10 20"

for genome in `ls $projectDir/results`; do
  for srx in `echo $projectDir/results/$genome/summary/*RX*.txt| xargs cat| awk -F '\t' '$3 + 0 == 0'| cut -f1`; do
    N=`cat "$projectDir/results/$genome/log/$srx.log.txt"| awk '{
      if ($0 ~ "Completed: 0K bytes transferred") x++
      if ($0 ~ "Server aborted session: No such file or directory") x++
      if ($0 ~ "ncbi_error_report.xml") x++
      if ($0 ~ "Stale file handle") x++
      if ($0 ~ "_1.fq: そのようなファイルやディレクトリはありません") x++
    } END {
      printf "%d", x
    }'`
    if [ $N -eq 0 ]; then  # SRA が存在しないとき、または Stale file handle エラーの場合は再実行しない
      ql=`sh $projectDir/sh/QSUB.sh mem`
      Logfile="$projectDir/results/$genome/log/$srx.log.txt"
      rm -f $Logfile
      qsub -N "srT$genome" -o $Logfile -e $Logfile -pe def_slot $nslot $ql $projectDir/sh/sraTailor.sh $srx $genome $projectDir "$QVAL"
    fi
  done
done

exit


####################################################################################
# 異常終了について (log.txt の中身)
####################################################################################

# SRA がないので、再実行しても不可能。 => reRunSraTailor では実行されない。
Completed: 0K bytes transferred in 0 seconds
Session Stop  (Error: Server aborted session: No such file or directory)

# fastqDump が異常に遅い (原因不明, 例: SRX100439, SRX100442) => reRunSraTailor では実行されない。
Stale file handle

# fastqDump の異常 (原因不明, 例: SRX103225) => reRunSraTailor では実行されない。
A report was generated into the file '/home/okishinya/ncbi_error_report.xml'.

# ペアエンドでない (原因不明, 例: SRX1010105) => reRunSraTailor では実行されない。
ls: cannot access SRX1010105_1.fq: そのようなファイルやディレクトリはありません


# 通信障害 (再実行可能)
ascp: failed to authenticate, exiting.
ascp: Cannot resolve target host., exiting.
Session Stop  (Error: failed to authenticate)
Session Stop  (Error: Session data transfer timeout)
Session Stop  (Error: Session initiation failed, read timed out)
Session Stop  (Error: Client unable to connect to server (check UDP port and firewall))

# メモリ不足 (メモリをあげれば再実行可能)
(コアダンプ)

