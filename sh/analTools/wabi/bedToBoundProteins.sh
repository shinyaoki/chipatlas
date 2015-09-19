#!/bin/sh
#$ -S /bin/sh

# sh chipatlas/sh/analTools/bedToBoundProteins.sh A.bed B.bed L.bed out.tsv

bedA="$1"   # 入力 BED ファイル (例: A.bed)
bedB="$2"   # 入力 BED ファイル (例: B.bed)
bedL="$3"   # 参照 BED ファイル (例: chipatlas/results/mm9/public/Oth.PSC.20.AllAg.AllCell.bed)
outF="$4"   # 出力ファイル      (例: out.tsv)
expL="/home/w3oki/chipatlas/lib/assembled_list/experimentList.tab"
tmpF="$outF.tmpForbedToBoundProteins"
tgt="bedA"
ref="bedB"
hed="Search for proteins significantly bound to Bed files."
cap="bedA vs bedB"

wclA=`cat $bedA| tr '|' '\n'| wc -l`
wclB=`cat $bedB| tr '|' '\n'| wc -l`

{
  cat $bedA| tr '|' '\n'| cut -f1-3| awk -F '\t' '{print $0 "\tA"}'
  cat $bedB| tr '|' '\n'| cut -f1-3| awk -F '\t' '{print $0 "\tB"}'
} > $tmpF

bedtools intersect -a $bedL -b $tmpF -wb| awk -F '\t' -v wclA=$wclA -v wclB=$wclB '{
  if ($8 == "A") a[$4]++
  else           b[$4]++
  SRX[$4]++
} END {
  for (srx in SRX) {
    printf "%s\t%d\t%d\t%d\t%d\n", srx, a[srx], wclA - a[srx], b[srx], wclB -b[srx]
  }
}'| awk '{
  print "echo " $0 " `/home/w3oki/bin/fisher -p " $2 " " $3 " " $4 " " $5 "`"
}'| sh 2>/dev/null| tr ' ' '\t' | awk -F '\t' '{
  for (i=1; i<NF; i++) printf "%s\t", $i
  print log($NF)/log(10)
}'| sort -k6n| /home/w3oki/bin/qval -lL -k6| awk -F '\t' -v expL=$expL '
BEGIN {
  while((getline < expL) > 0) a[$1] = $3 "\t" $4 "\t" $5 "\t" $6
} {
  if ($4 == 0) Fold = "inf"
  else         Fold = $2 * ($4+$5) / $4 / ($2+$3)  # (a/Ea) / (b/Eb)
  printf "%s\t%s\t%s/%s\t%s/%s\t%s\t%s\t%s\n", $1, a[$1], $2, $2+$3, $4, $4+$5, $6, $7, Fold
}'| awk -F '\t' -v tgt="$tgt" -v ref="$ref" -v hed="$hed" -v cap="$cap" '
BEGIN {
  while ((getline < "/home/w3oki/bin/btbpToHtml.txt") > 0) {
    sub("___Title___", cap, $0)
    sub("___Targets___", tgt, $0)
    sub("___References___", ref, $0)
    sub("___Header___", hed, $0)
    sub("___Caption___", cap, $0)
    print
  }
} {
  print "<tr>"
  print "<td title=\"Open this Info...\"><a target=\"_blank\" style=\"text-decoration: none\" href=\"http://devbio.med.kyushu-u.ac.jp/SRX_html/" $1 "\">" $1 "</a></td>"
  for (i=2; i<=5; i++) print "<td>" $i "</td>"
  for (i=6; i<=7; i++) printf "<td align=\"right\">%s</td>\n", $i
  for (i=8; i<NF; i++) printf "<td align=\"right\">%.1f</td>\n", $i
  printf "<td align=\"right\">%.2f</td>\n", $i
  printf "<td>%s</td>\n", ($NF > 1)? "TRUE" : "FALSE"
  print "</tr>"
} END {
  print "</tbody>"
  print "</table>"
}'> $outF







rm $tmpF

#       ある SRX と重なる   重ならない
# bedA              a         c       a+c = bedA の行数 (= wclA)
# bedB              b         d       b+d = bedB の行数 (= wclB)

# Fisher a b c d

# SRX499128   TFs and others    Pou5f1    Pluripotent stem cell   EpiLC   5535/18356    1801/2623   -310.382    -307.491     0.439
# SRX         抗原大             抗原小     細胞大                   細胞小     a / wclA      b / wclB    p-Val     q-Val (BH)   (a / aの期待値) / (b / bの期待値)
