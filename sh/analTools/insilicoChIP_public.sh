#!/bin/sh
#$ -S /bin/sh

mkdir -p chipatlas/results/hg19/insilicoChIP_preProcessed/isc
# これは全て /mnt/kyushu/data/isc/ と同期

# GWAS の公開用リスト
cat chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/results/gwaslist.html| awk '{
  if ($0 ~ "Search for proteins significantly bound") next
  if ($0 ~ "<tr style=") $0 = $0 "\n<th>GWAS trait</th>\n<th>Num of LD-DHS</th>\n<th>Min(Log P)</th>"
  if ($0 ~ "<th title=") next
  if ($0 ~ "aaSorting") sub(/[56]/, "0", $0)

  if ($0 ~ "<td><a target") {
    split($0, a, ">")
    sub("</td", "", a[6])
    getline
    split($0, b, ":")
    id = substr(b[4], 1, 4)
    $0 = "<td><a target=\"_blank\" style=\"text-decoration: none\" href=\"http://dbarchive.biosciencedbc.jp/kyushu-u/isc/GWAS:" id ".html\">" a[6] "</a></td>"
  }
  
  if ($0 ~ "gwas/bed") {
    split($0, c, ">")
    sub("</a", "", c[3])
    strA = "<td align=\"right\">" c[3] "</td>"
    getline
    split($0, d, ">")
    sub("</td", "", d[2])
    strB = "<td align=\"right\">" d[2] "</td>"
    getline
    $0 = strA "\n" strB
  }
  if ($0 == "</table>") {
    print
    exit
  }
  print
}' > chipatlas/results/hg19/insilicoChIP_preProcessed/isc/gwas.html


# FF enhancer の公開用リスト
cat chipatlas/results/hg19/insilicoChIP_preProcessed/fantomEnhancer/results/fantomEnhancerlist.html| awk '{
  if ($0 ~ "Search for proteins significantly bound") next
  if ($0 ~ "<tr style=") $0 = $0 "\n<th>Cell type or anatomic facet</th>\n<th>Num of enhancers</th>\n<th>Min(Log P)</th>"
  if ($0 ~ "<th title=") next
  if ($0 ~ "aaSorting") sub(/[56]/, "0", $0)

  if ($0 ~ "<td><a target") {
    split($0, a, ">")
    sub("</td", "", a[6])  # a[6] = ID
    getline
    split($0, b, ">")
    sub("</td", "", b[2])  # b[2] = facet
    getline
    $0 = "<td><a target=\"_blank\" style=\"text-decoration: none\" href=\"http://dbarchive.biosciencedbc.jp/kyushu-u/isc/" a[6] ".html\">" b[2] "</a></td>"
  }
  
  if ($0 ~ "fantomEnhancer/bed") {
    split($0, c, ">")
    sub("</a", "", c[3])
    strA = "<td align=\"right\">" c[3] "</td>"
    getline
    split($0, d, ">")
    sub("</td", "", d[2])
    strB = "<td align=\"right\">" d[2] "</td>"
    getline
    $0 = strA "\n" strB
  }
  if ($0 == "</table>") {
    print
    exit
  }
  print
}' > chipatlas/results/hg19/insilicoChIP_preProcessed/isc/FFenhancer.html


# 結果の html を加工
for fn in `ls chipatlas/results/hg19/insilicoChIP_preProcessed/*[gE]*/results/tsv/*.html`; do
  outFn="chipatlas/results/hg19/insilicoChIP_preProcessed/isc/"`basename $fn`
  grep -v "<caption>Downloads:" $fn > $outFn
done
