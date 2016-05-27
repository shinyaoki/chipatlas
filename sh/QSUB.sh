#!/bin/sh
#$ -S /bin/sh
mode=0
short=`for qName in week_hdd.q week_ssd.q short.q; do
  qstat -f| grep $qName| awk -v qName=$qName '{
    split($3, arr, "/")
    x = x + arr[2]
    y = y + arr[3]
  } END {
    print y-x "\t" qName
  }'
done| sort -k1nr| head -n1| awk '{
  if ($2 == "short.q") printf "-l short"
}'`

Para=$(for i in `seq $#`; do
  p=`eval echo '\ $'{$i}`
  echo "$p"
done| sed 's/^ //'| awk -F '\t' '{
  if ($1 ~ " ") $1 = "\"" $1 "\""
  printf "%s ", $1
}')

if [ $1 = "shortOrweek" ]; then
  echo -n $short
elif [ $1 = "mem" ]; then
  bin/qm| head -n5| awk '{
    if ($1 ~ "week") w += $4 -$2
    else if ($1 ~ "short") s += $4 - $2
  } END {
    if (w < s) printf "-l short"
  }'
else
  echo qsub $short $Para| sh
fi



