#!/bin/sh
#$ -S /bin/sh

projectDir=xhipome_ver3
Genome=hg19
bedtools="$projectDir/bin/bedtools-2.17.0/bin/bedtools"
width=2500

# refFlat より、TSSリストを作成
curl http://hgdownload.cse.ucsc.edu/goldenPath/$Genome/database/refFlat.txt.gz| gunzip| awk -F '\t' '{
  if ($4 == "+") TSS = $5
  else           TSS = $6
  printf "%s\t%s\t%s\t%s\n", $3, TSS, $1, $2
}'|\
# 同じ遺伝子で同じ TSS を除去
awk '!a[$1, $2, $3]++'|\
# haplotype chromosomes を除去
awk '$1 !~ "_hap"'|\
awk -F '\t' '{printf "%s\t%s\t%s\t%s\t%s\n", $1, $2, $2, $3, $4}' > aaa/TSS.$Genome.bed



qVal=20
inBn="aaa/ALL.PSC.$qVal.AllAg.AllCell"
cat $inBn.AG.html| awk '{if($1!="" && $1 !~ ":") print "[" $1 "]_"}' > $inBn.ag.tmp   # [NANOG]_
fgrep -f $inBn.ag.tmp $inBn.bed| tr '[]' '\t\t'| cut -f5,9| awk '!a[$0]++' > $inBn.SRX.tmp  # NANOG	SRX266862



qProt=FOXH1
Num=0
unset allSRX
for qSRX in `awk -v qProt=$qProt '{if ($1 == qProt) print $2}' $inBn.SRX.tmp| sort -n`; do  # qSRX =	SRX266862
  $bedtools window -a $projectDir/results/$Genome/Bed05/Bed/$qSRX.05.bed -b aaa/TSS.$Genome.bed -w $width|\
  awk -F '\t' -v qProt=$qProt -v qSRX=$qSRX '{
    Score[$8,$9] = Score[$8,$9] + $4
  } END {
    for (key in Score) {
      split(key, arr, SUBSEP)
      printf "%s\t%s\t%s\t%s\t%s\n", qProt, qSRX, arr[1], arr[2], Score[key]
    }
  }'
  let Num=$Num+1
  allSRX=$allSRX" "$qSRX
done > $qProt.txt   # POU5F1  SRX021071  CDX2  NM_001265  493

cat $qProt.txt| awk -F '\t' -v qProt=$qProt -v Num=$Num '{
  Sum[$3,$4] = Sum[$3,$4] + $5
} END {
  inFn = qProt ".txt"
  while ((getline < inFn) > 0) {
    print $0 "\t" Sum[$3,$4] / Num
  }
}'| awk '{
  sub("_", "\t", $4)  # NM_005612 のアンダースコアをタブに置換
  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5, $6, $7
}'| sort -k7nr -k5n -k2n| awk -F '\t' -v qProt=$qProt -v allSrx="$allSRX" '
BEGIN {
  Nsrx = split(allSrx, SRX, " ")
  i = 1
} {
  if (i > Nsrx) {
      printf "\n"
      i = 1
    }
    
  if (i == 1) printf "%s\t%s_%s\t%s", $3, $4, $5, $7
  
  while (i <= Nsrx) {
    if ($2 == SRX[i]) {
      printf "\t%s", $6
      i++
      break
    } else {
      printf "\t0"
      i++
    }
  }
} END {
  for (j=1; j < Nsrx-i+2; j++) printf "\t0"
  printf "\n"
}'| awk -F '\t' -v qProt=$qProt -v allSRX="$allSRX" -v width=$width '
BEGIN {
  gsub(" ", "\t", allSRX)
  printf "%s\t%s\tAvr%s\n", qProt, width, allSRX
} {
  print
}' > $qProt.target.tsv
  
  

# Avr でソート
# FOXH1	2500	Avr		SRX064484	SRX064493
# CER1	NM_005454	2323	1964	2682
# ZNF664	NM_001204298	2233.5	2227	2240
