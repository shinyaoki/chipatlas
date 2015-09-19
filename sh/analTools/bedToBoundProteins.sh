#!/bin/sh
#$ -S /bin/sh

# sh chipatlas/sh/analTools/bedToBoundProteins.sh A.bed B.bed L.bed out.tsv
shufN=1

while getopts s: option
do
  case "$option" in
    s) shufN="$OPTARG" ;;  # bedB が Shuffle data のときの shuffle の回数
  esac
done

shift `expr $OPTIND - 1`

bedA="$1"   # 入力 BED ファイル (例: A.bed)
bedB="$2"   # 入力 BED ファイル (例: B.bed)
bedL="$3"   # 参照 BED ファイル (例: chipatlas/results/mm9/public/Oth.PSC.20.AllAg.AllCell.bed)
outF="$4"   # 出力ファイル      (例: out.tsv)
expL="/home/okishinya/chipatlas/lib/assembled_list/experimentList.tab"
tmpF="$outF.tmpForbedToBoundProteins"

wclA=`cat $bedA| wc -l`
wclB=`cat $bedB| wc -l`

{
  cut -f1-3 $bedA| awk -F '\t' '{print $0 "\tA"}'
  cut -f1-3 $bedB| awk -F '\t' '{print $0 "\tB"}'
}| awk '{print $0 "\t" NR}'| bin/qsortBed > $tmpF

#  chr1    3021366 3021399 ERX132628       chr1    3020993 3021399 B       5791830

for bedL in `ls $bedL.*`; do
  awk '{x[$4]++} END {for (i in x) print i "\t" x[i]}' $bedL >> "$tmpF"3 &
  software/bedtools2/bin/bedtools intersect -sorted -a $bedL -b $tmpF -wb >> "$tmpF"2
done

cat "$tmpF"2| awk -F '\t' -v wclA=$wclA -v wclB=$wclB -v shufN=$shufN '{
  if(NR % 1000000 == 0) delete x
  if (!x[$4,$9]++) {
    if ($8 == "A") a[$4]++
    else           b[$4]++
  }
  SRX[$4]++
} END {
  for (srx in SRX) {
    printf "%s\t%d\t%d\t%d\t%d\n", srx, a[srx], wclA - a[srx], int(b[srx] / shufN + 0.5), wclB / shufN -int(b[srx] / shufN + 0.5)
  }
}'| awk '{
  print "echo " $0 " `/home/okishinya/bin/fisher -p " $2 " " $3 " " $4 " " $5 "`"
}'| sh 2>/dev/null| tr ' ' '\t' | awk -F '\t' '{
  for (i=1; i<NF; i++) printf "%s\t", $i
  if ($NF == 0) print "-324"
  else          print log($NF)/log(10)
}'| sort -k6n| /home/okishinya/bin/qval -lL -k6| awk -F '\t' -v expL=$expL '
BEGIN {
  while((getline < expL) > 0) a[$1] = $3 "\t" $4 "\t" $5 "\t" $6
} {
  if ($3*$4 == 0) FE = "inf"
  else            FE = ($2/($2+$3))/($4/($4+$5))  # Fold enrichment = (a/ac)/(b/bd)
  printf "%s\t%s\t%s/%s\t%s/%s\t%s\t%s\t%s\n", $1, a[$1], $2, $2+$3, $4, $4+$5, $6, $7, FE
}'| sort -t $'\t' -k9n -k10nr| awk -F '\t' -v tmp="$tmpF"3 '
BEGIN {
  while ((getline < tmp) > 0) peakN[$1] += $2
} {
  if ($2$4 !~ "No description" && $2$4 !~ "Unclassified") {
    for (i=1; i<=5; i++) printf "%s\t", $i
    printf "%d\t", peakN[$1]
    for (i=6; i<=NF; i++) printf "%s\t", $i
    printf "\n"
  }
}' > $outF

rm $tmpF "$tmpF"2 "$tmpF"3

#       ある SRX と重なる   重ならない
# bedA              a         c       a+c = bedA の行数 (= wclA)
# bedB              b         d       b+d = bedB の行数 (= wclB)

# Fisher a b c d

# SRX499128   TFs and others    Pou5f1    Pluripotent stem cell   EpiLC   2453   5535/18356    1801/2623   -310.382    -307.491     0.439
# SRX         抗原大             抗原小     細胞大                   細胞小   peak数  a / wclA      b / wclB    p-Val     q-Val (BH)   列7,8の Fold Enrichment








