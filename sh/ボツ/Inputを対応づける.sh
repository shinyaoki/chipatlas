




cat chipatlas/lib/assembled_list/experimentList.tab| awk -F '\t' '{
  N = split($9, a, " ")
  for (i=1; i<=N; i++) print $1 "\t" $3 "\t" a[i]
}'| tr -d '.:;'| grep -v GSM| awk '!a[$1,$2,$3]'| awk -F '\t' '{
  if ($2 == "Input control") {
    b[$3]++
    c++
    k[$3]++
  } else if ($3 != "No description" && $3 != "Unclassified") {
    B[$3]++
    C++
    k[$3]++
  }
} END {
  for (key in k) printf "%d\t%d\t%d\t%d\t%s\n", b[key], c - b[key], B[key], C - B[key], key
}'| awk -F '\t' '$1 > 5 && $1/$2 > $3/$4'| while read line; do
  pval=$(fisher -p `echo $line| cut -f1-4` 2>/dev/null)
  pval=`echo $pval| awk '{printf "%d", ($1 > 0) ? log($1) / log(10) : -324}'`
  echo $pval $line| tr ' ' '\t'
done| tee aaa

# Input のタイトルで多いもの
-200	293	38292	26	207853	WCE
-230	343	38242	34	207845	IgG
-324	1085	37500	265	207614	input
-324	2724	35861	361	207518	Input



cat chipatlas/lib/assembled_list/experimentList.tab| awk -F '\t' '{
  for (j=10; j<=NF; j++) {
    split($j, atr, "=")
    N = split(atr[2], a, " ")
    for (i=1; i<=N; i++) print $1 "\t" $3 "\t" a[i]
  }
}'| tr -d '.:;'| grep -v GSM| awk '!a[$1,$2,$3]'| awk -F '\t' '{
  if ($2 == "Input control") {
    b[$3]++
    c++
    k[$3]++
  } else if ($3 != "No description" && $3 != "Unclassified") {
    B[$3]++
    C++
    k[$3]++
  }
} END {
  for (key in k) printf "%d\t%d\t%d\t%d\t%s\n", b[key], c - b[key], B[key], C - B[key], key
}'| awk -F '\t' '$1 > 50 && $1/$2 > $3/$4'| while read line; do
  pval=$(fisher -p `echo $line| cut -f1-4` 2>/dev/null)
  pval=`echo $pval| awk '{printf "%d", ($1 > 0) ? log($1) / log(10) : -324}'`
  echo $pval $line| tr ' ' '\t'
done| tee bbb

# 属性値で多いもの
-106	175	120923	28	629904	WCE
-126	562	120536	689	629243	IgG
-158	387	120711	205	629727	Control
-324	1154	119944	769	629163	Input
-324	2231	118867	794	629138	none
-324	2417	118681	3753	626179	N/A





#  Google Refine で Input を指定するためのスクリプト
mkdir -p xxx
cat chipatlas/lib/metadata/NCBI_SRA_Metadata_Full_20160101.metadata.tab| awk -v OFS='\t' -F '\t' '
BEGIN {
  while ((getline < "chipatlas/lib/assembled_list/experimentList.tab") > 0) {
    srx[$1]++
    gnm[$1] = $2
    ttl[$1] = $9
  }
} {
  atr=""
  if (srx[$1] > 0) {
    url = "http://www.ncbi.nlm.nih.gov/sra/?term=" $1
    for (i=18; i<=NF; i++) {
      split($i, a, "=")
      atr = atr "|" a[2]
    }
    sub("\\|", "", atr)
    print $12, $1, url, ttl[$1], atr, gnm[$1]
  }
}'| sort| awk -F '\t' -v OFS='\t' '{
  fn = "xxx/" $6 ".tab"
  if (!a[$6]++) print "SRA", "SRX", "URL", "Title", "Metadata", "Input_SRX" > fn
  print $1, $2, $3, $4, $5, "1" > fn
}'






