#!/bin/sh
#$ -S /bin/sh
# sh chipatlas/sh/refineSearchList.sh

cat chipatlas/lib/assembled_list/experimentList.tab| awk -F '\t' -v template="chipatlas/sh/refineSearchList.html" '
BEGIN {
  simp = "checked=\"checked\""
  adva = "onclick=\"location.href = \047http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/refineSearchList_advanced.html\047\""
  while ((getline < template) > 0) {
    sub("__1__", simp, $0)
    sub("__2__", adva, $0)
    sub("__sortKey__", "5", $0)
    
    if ($0 !~ "by authors") print
  }
} {
  if ($9 ~ /^GSM[0-9][0-9][0-9][0-9]/) {
    sub(": ", SUBSEP, $9)
    split($9, g, SUBSEP)
    gsm = g[1]
    gstag = " title=\"Open this Info...\"><a target=\"_blank\" style=\"text-decoration: none\" href=\"http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=" gsm "\"</a"
    $9 = g[2]
  } else {
    gsm = "-"
    gstag = ""
  }
  print "<tr>"
  print "<td title=\"Open this Info...\"><a target=\"_blank\" style=\"text-decoration: none\" href=\"http://chip-atlas.org/view?id=" $1 "\">" $1 "</a></td>"
  print "<td" gstag ">" gsm "</td>"
  print "<td>" $2 "</td>"
  print "<td>" $3 "</td>"
  print "<td>" $4 "</td>"
  print "<td>" $5 "</td>"
  print "<td>" $6 "</td>"
} END {
  print "</tbody>"
  print "</table>"
}' > chipatlas/lib/assembled_list/refineSearchList.html


cat chipatlas/lib/assembled_list/experimentList.tab| awk -F '\t' -v template="chipatlas/sh/refineSearchList.html" '
BEGIN {
  simp = "onclick=\"location.href = \047http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/refineSearchList.html\047\""
  adva = "checked=\"checked\""
  while ((getline < template) > 0) {
    sub("ChIP-Atlas / Keyword search", "ChIP-Atlas / Advanced keyword search")
    sub("__1__", simp, $0)
    sub("__2__", adva, $0)
    sub("__sortKey__", "5", $0)
    print
  }
} {
  if ($9 ~ /^GSM[0-9][0-9][0-9][0-9]/) {
    sub(": ", SUBSEP, $9)
    split($9, g, SUBSEP)
    gsm = g[1]
    gstag = " title=\"Open this Info...\"><a target=\"_blank\" style=\"text-decoration: none\" href=\"http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=" gsm "\"</a"
    $9 = g[2]
  } else {
    gsm = "-"
    gstag = ""
  }
  atr = ""
  for (i=10; i<=NF; i++) {
    $i = "<b>" $i
    sub("=", "=</b>", $i)
    atr = atr "<br>" $i
  }
  sub("<br>", "", atr)
  print "<tr>"
  print "<td title=\"Open this Info...\"><a target=\"_blank\" style=\"text-decoration: none\" href=\"http://chip-atlas.org/view?id=" $1 "\">" $1 "</a></td>"
  print "<td" gstag ">" gsm "</td>"
  print "<td>" $2 "</td>"
  print "<td>" $3 "</td>"
  print "<td>" $4 "</td>"
  print "<td>" $5 "</td>"
  print "<td>" $6 "</td>"
  print "<td>" $9 "</td>"
  print "<td>" atr "</td>"
} END {
  print "</tbody>"
  print "</table>"
}' > chipatlas/lib/assembled_list/refineSearchList_advanced.html
