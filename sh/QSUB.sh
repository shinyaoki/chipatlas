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
else
  echo qsub $short $Para| sh
fi
