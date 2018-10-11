#!/bin/sh
#$ -S /bin/sh
mode=0
short=`for qName in month_hdd.q month_ssd.q short.q; do
  qstat -f| grep $qName| awk -v qName=$qName '{
    split($3, arr, "/")
    x = x + arr[2]
    y = y + arr[3]
  } END {
    print y-x "\t" qName
  }'
done| sort -k1nr| head -n1| awk '{
  if ($2 == "short.q") printf "-l short"
  else                 printf "%s", " "
}'`

Para=$(for i in `seq $#`; do
  p=`eval echo '\ $'{$i}`
  echo "$p"
done| sed 's/^ //'| awk -F '\t' '{
  if ($1 ~ " ") $1 = "\"" $1 "\""
  printf "%s ", $1
}')

conf=`cat bin/conf.ql.txt`  # 1: week.q  2: short.q  3: debug.q  0: 強制を解除

if [ $1 = "shortOrweek" ]; then
  echo -n "$short"| awk -v conf=$conf '{
    if (conf == 0) printf "%s", $0
    if (conf == 1) printf " "
    if (conf == 2) printf "-l short"
    if (conf == 3) printf "-l debug"
  }'
elif [ $1 = "mem" ]; then
  bin/qm| head -n9| awk '{
    if ($1 ~ "month" && $1 !~ "medium") w += $4 - $2
    else if ($1 ~ "short") s += $4 - $2
  } END {
    if (w < s) printf "-l short"
    else printf " "
  }'| awk -v conf=$conf '{
    if (conf == 0) printf "%s", $0
    if (conf == 1) printf " "
    if (conf == 2) printf "-l short"
    if (conf == 3) printf "-l debug"
    if (conf == 4) printf "-l month -l medium"
  }'
else
  echo qsub "$short" $Para| sh
fi
