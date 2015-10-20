#!/bin/sh
#$ -S /bin/sh

# sh chipatlas/sh/analTools/btbpToHtml.sh inTSV TargetName ReferenceName

# inTSV の内容
# SRX499128   TFs and others    Pou5f1    Pluripotent stem cell   EpiLC   2453   5535/18356    1801/2623   -310.382    -307.491     0.439
# SRX         抗原大             抗原小     細胞大                   細胞小   peak数  a / wclA      b / wclB    p-Val     q-Val (BH)   列7,8の Fold Enrichment

inTSV="$1"
tgt="$2"
ref="$3"
hed="Search for proteins significantly bound to Bed files."
cap="$4"
srxUrl="http://chip-atlas.org/view?id="



cat $inTSV| awk -F '\t' -v tgt="$tgt" -v ref="$ref" -v hed="$hed" -v cap="$cap" -v srxUrl=$srxUrl '
BEGIN {
  while ((getline < "chipatlas/sh/analTools/btbpToHtml.txt") > 0) {
    gsub("___Title___", cap, $0)
    gsub("___Targets___", tgt, $0)
    gsub("___References___", ref, $0)
    gsub("___Header___", hed, $0)
    gsub("___Caption___", cap, $0)
    print
  }
} {
  print "<tr>"
  print "<td title=\"Open this Info...\"><a target=\"_blank\" style=\"text-decoration: none\" href=\"" srxUrl $1 "\">" $1 "</a></td>"
  for (i=2; i<=5; i++) print "<td>" $i "</td>"
  for (i=6; i<=8; i++) printf "<td align=\"right\">%s</td>\n", $i
  for (i=9; i<=10; i++) printf "<td align=\"right\">%.1f</td>\n", $i
  printf "<td align=\"right\">%.2f</td>\n", $11
  printf "<td>%s</td>\n", ($11 > 1)? "TRUE" : "FALSE"
  print "</tr>"
} END {
  print "</tbody>"
  print "</table>"
}'
