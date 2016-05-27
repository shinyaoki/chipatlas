#!/bin/sh
#$ -S /bin/sh

# qsub chipatlas/sh/analTools/insilicoChIP_FantomEnhancer.sh

extd=1000
geneBody="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/hg19_allGeneBody.bed"
exons="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/hg19_allExons.bed"
gwasCatalog="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/gwasCatalog_original.bed"
ldBlock="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/ld_0.9_EUR.txt"
gwasLD="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/gwas_original+LD0.9.bed"
allGWAS="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/allGWASfor_insilicoChIP.bed"
allGWASuniq="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/allGWASfor_insilicoChIP_uniq.bed"
dhsBed="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/DHS.10.merged.bed"
dhsLDuniq="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/allLD-DHS_uniq.bed"
summerizedTSV="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/results/summerized.tsv"
qVal=2

mkdir -p chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib
mkdir -p chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/bed
mkdir -p chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/ldDhsBed
mkdir -p chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/results/tsv


##########################################################################################################################################################################
#                                                                         GWAS catalog
##########################################################################################################################################################################
# Gene body BED ファイルの作成
curl "http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/refFlat.txt.gz"| gunzip| cut -f3,5,6| sort -k1,1 -k2,2n| bedtools merge -i stdin > "$geneBody"

# Exon BED ファイルの作成
curl "http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/refFlat.txt.gz"| gunzip| awk -F '\t' -v OFS='\t' '{
  split($10, a, ",")
  split($11, b, ",")
  for (i=1; i<length(a); i++) print $3, a[i], b[i]
}'| sort -k1,1 -k2,2n| bedtools merge -i stdin > "$exons"

# GWAS の ダウンロード
    # 除去 %&()*+.:;
    # そのまま ',-
    # スペースに /
curl http://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/gwasCatalog.txt.gz| gunzip| cut -f2-| sort -t $'\t' -k10| awk -F '\t' '{
  trait = $10
  gsub(/Red vs\. non-red hair color/, "Red vs  non-red hair color", trait)
  gsub(/[%&\(\)\*+\.\:\;]/, "", trait)
  gsub(/\//, " ", trait)
  gsub(/ /, "_", trait)
  if (!a[trait]++) i++
  printf "%s\t%04d\t%s\n", $0, i, trait
}' > "$gwasCatalog" # $1-3 = BED,  $9 = title, $10 = trait, $23 = ID for trait, $24 = 記号文字を修正した trait

# LD block の ダウンロード (1000G phase 3, r2 = 0.9, EUR)
curl http://www.broadinstitute.org/mpg/snpsnap/database/EUR/ld0.9/ld0.9_collection.tab.gz| gunzip > "$ldBlock"

# GWAS catalog に LD block をひもづける
cat "$ldBlock"| awk -F '\t' -v gwasCatalog="$gwasCatalog" '
BEGIN {
  while ((getline < gwasCatalog) > 0) g[$4]++
  close(gwasCatalog)
} {
  if (g[$2] > 0) r[$2] = $10 "\t" $11
} END {
  while ((getline < gwasCatalog) > 0) {
    if (!r[$4]) r[$4] = $3 "\t" $3
    print $0 "\t" r[$4]
  }
}' > "$gwasLD"
# $1   $2   $3   $10    $23   $24             $25     $26
# chr  beg  end  trait  ID    修正済みtrait    LD_beg  LD_end


# 疾患特異的 LD+extension BED ファイルの作成
cat "$gwasLD"| awk -F '\t' -v extd=$extd '{
  print $1 "\t" $25 - extd "\t" $26 + extd "\t" $23 "\t" $24
}'| bedtools intersect -v -a stdin -b "$exons"| sort -k1,1 -k2,2n| uniq| tee "$allGWAS"| awk '{
  bed = "chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/bed/GWAS:" $4 ".bed"
  print >> bed
  close(bed)
}'
cut -f1-3 "$allGWAS"| uniq > "$allGWASuniq"

# DNase-seq データのマージ
cat chipatlas/results/hg19/public/DNS.ALL.10.DNase-Seq.AllCell.bed| mergeBed -i stdin > "$dhsBed"

# 各種疾患 LD-block のうち、DHS と重なるものを抽出
rm -f rm tmp/insilicoChIP_preProcessedgwas*
ql=`sh chipatlas/sh/QSUB.sh mem`
for bed in `ls "chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/bed/"*bed`; do
  outBed=`echo "$bed"| sed 's[/bed/[/ldDhsBed/['`
  echo "intersectBed -a \"$dhsBed\" -b \"$bed\"| sort -k1,1 -k2,2n| mergeBed -i stdin > \"$outBed\""
done > tmp/insilicoChIP_preProcessedgwas
split -l 20 tmp/insilicoChIP_preProcessedgwas tmp/insilicoChIP_preProcessedgwasx

for tmp in `ls tmp/insilicoChIP_preProcessedgwasx*`; do
  cat $tmp| qsub $ql -o /dev/null -e /dev/null -N LD-DHS
done

while :; do
  qN=`qstat| awk '$3 == "LD-DHS"'| wc -l`
  if [ $qN -eq 0 ]; then
    rm tmp/insilicoChIP_preProcessedgwas*
    break
  fi
done

# すべての疾患 LD-DHS を作成
cat chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/ldDhsBed/*bed| sort -k1,1 -k2,2n| uniq > "$dhsLDuniq"

# LD-DHS で疾患特異的 GWAS とその他の GWAS で in silico ChIP
ql=`sh chipatlas/sh/QSUB.sh mem`
for txt in `ls "chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/ldDhsBed/"*bed| awk -F '\t' -v gwasCatalog="$gwasCatalog" '
BEGIN {
  while ((getline < gwasCatalog) > 0) a[$23] = $24
  FS = "/"
} {
  fn = $0
  sub("GWAS:", "", $NF)
  sub(".bed", "", $NF)
  print fn "@" a[$NF]
}'`; do
  bed=`echo $txt| cut -d '@' -f1`
  wcl=`cat "$bed"| wc -l`
  outFn=`echo $bed| sed 's/.bed$//g'| sed 's[/ldDhsBed/[/results/tsv/[g'`
  bn=`echo $txt| cut -d '@' -f2| tr '_' ' '`
  if [ $wcl -ge 1 ]; then # 登録数が 1 以上のみ in silico ChIP をおこなう
    qsub $ql -o /dev/null -e /dev/null -N iscGWAS bin/insilicoChIP -a "$bed" -b "$dhsLDuniq" -Q 10 -A "$bn" -B "Other GWAS" -T "$bn vs Other GWAS" -v -o bed hg19 "$outFn"
  fi > /dev/null
done

while :; do
  qN=`qstat| awk '$3 == "iscGWAS"'| wc -l`
  if [ $qN -eq 0 ]; then
    sh chipatlas/sh/analTools/preProcessed_insilicoChIP.sh P gwas $qVal hg19
    break
  fi
done


exit

