#!/bin/sh
#$ -S /bin/sh

# qsub chipatlas/sh/analTools/insilicoChIP_GWAS.sh
projectDir=chipatlas
extd=1000
geneBody="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/hg19_allGeneBody.bed"
snpLoci="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/snpLoci.bed"
exons="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/hg19_allExons.bed"
gwasCatalog="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/gwasCatalog_original.bed"
ldBlock="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/ld_0.9_EUR.txt"
gwasLD="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/gwas_original+LD0.9.bed"
allGWAS="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/allGWASfor_insilicoChIP.bed"
allGWASuniq="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/allGWASfor_insilicoChIP_uniq.bed"
dhsBed="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/DHS.10.merged.bed"
dhsLDuniq="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/allLD-DHS_uniq.bed"
summerizedTSV="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/results/summerized.tsv"
id2name="chipatlas/lib/id2name4Gwas.tab"
qVal=2

mkdir -p chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib
mkdir -p chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/bed
mkdir -p chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/ldDhsBed
mkdir -p chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/results/tsv


##########################################################################################################################################################################
#                                                                         GWAS catalog
##########################################################################################################################################################################
# Gene body BED ファイルの作成
cat $projectDir/lib/ucsc_tmp/hg19.refFlat.txt.gz| gunzip| cut -f3,5,6| sort -k1,1 -k2,2n| software/bedtools2/bin/bedtools merge -i stdin > "$geneBody"

# Exon BED ファイルの作成
cat $projectDir/lib/ucsc_tmp/hg19.refFlat.txt.gz| gunzip| awk -F '\t' -v OFS='\t' '{
  split($10, a, ",")
  split($11, b, ",")
  for (i=1; i<length(a); i++) print $3, a[i], b[i]
}'| sort -k1,1 -k2,2n| chipatlas/bin/bedtools-2.17.0/bin/bedtools merge -i stdin > "$exons"


# GWAS ID の作成 (初めての時のみ)
if [ ! `ls "$id2name"` ]; then
  cat $projectDir/lib/ucsc_tmp/gwasCatalog.txt.gz| gunzip| cut -f2-| sort -t $'\t' -k10| awk -F '\t' '{
    trait = $10
    gsub(/Red vs\. non-red hair color/, "Red vs  non-red hair color", trait)
    gsub(/[%&\(\)\*+\.\:\;]/, "", trait)
    gsub(/\//, " ", trait)
    gsub(/ /, "_", trait)
    if (!a[trait]++) {
      i++
      printf "%04d\t%s\n", i, trait
    }
  }' > "$id2name"
fi

# GWAS の ダウンロード
    # 除去 %&()*+.:;
    # そのまま ',-
    # スペースに /
    
  # GWAS Catalog には同じ rs 番号でも、複数箇所存在することがある。その全てが hap chromosome
  # 例) rs17207986
  # chr6            32079566 32079567 rs17207986
  # chr6_cox_hap2   3550228  3550229  rs17207986
  # chr6_dbb_hap3   3358740  3358741  rs17207986
  # chr6_mcf_hap5   3459394  3459395  rs17207986
  # chr6:32079567 (1000G データ)
  
  # しかも 同じ rs 番号でも 1000G と GWAS で座位が異なることもある (GWAS のほうがマチガイ)
  #            1000G (正)   GWAS (誤)
  # rs5031002  23:66942625  X:66942625
  
  # したがって同じ rs で同じ trait の重複は削除する。
  # GWAS の rs と座位が 1000G のそれと一致したときのみ LD-block をつける。一致しない場合は GWAS の座位のまま。
  
cat $projectDir/lib/ucsc_tmp/gwasCatalog.txt.gz| gunzip| cut -f2-| sort -t $'\t' -k10| awk -F '\t' -v id2name="$id2name" '
BEGIN {
  while ((getline < id2name) > 0) {
    x[$2] = $1 + 0
    lastId = $1 + 0
  }
} {
  trait = $10
  gsub(/Red vs\. non-red hair color/, "Red vs  non-red hair color", trait)
  gsub(/[%&\(\)\*+\.\:\;]/, "", trait)
  gsub(/\//, " ", trait)
  gsub(/ /, "_", trait)

  if (!x[trait]) {
    lastId++
    x[trait] = lastId  # 新しく入った trait に 新規 ID を発行
  }
  printf "%s\t%04d\t%s\n", $0, x[trait], trait
}'| awk -F '\t' '!a[$4, $10]++'| sort -t $'\t' -k23n > "$gwasCatalog"  # $1-3 = BED, $4 = SNP ID, $9 = title, $10 = trait, $23 = ID for trait, $24 = 記号文字を修正した trait
cut -f23- "$gwasCatalog"| awk '!a[$0]++' > "$id2name"

# LD block の ダウンロード (1000G phase 3, r2 = 0.9, EUR)
curl https://data.broadinstitute.org/mpg/snpsnap/database/EUR/ld0.9/ld0.9_collection.tab.gz| gunzip > "$ldBlock"
# $1           $2          $10 LD-left   $11 LD-right   (注: $1 の座標は gwasCatalog の $1:$3 に相当)
# 4:98562671   rs9999992   98552585      98643888


# GWAS catalog に LD block をひもづける
cat "$ldBlock"| awk -F '\t' -v gwasCatalog="$gwasCatalog" '
BEGIN {
  while ((getline < gwasCatalog) > 0) g[$4]++
  close(gwasCatalog)
} {
  if (g[$2] > 0) {
    p[$2] = $1
    r[$2] = $10 "\t" $11
  } else {
    delete g[$2]
  }
} END {
  while ((getline < gwasCatalog) > 0) {
    locus = substr($1, 4, 100) ":" $3
    if (length(r[$4]) == 0 || locus != p[$4]) r[$4] = $3 "\t" $3
    print $0 "\t" r[$4]
  }
}' > "$gwasLD"
# $1   $2   $3   $4      $10    $23   $24             $25     $26
# chr  beg  end  SNP_ID  trait  ID    修正済みtrait    LD_beg  LD_end
# 注意: a[$10, $25, $26] は重複がある (同じ LD-block 内に $123 があるため)


# 疾患特異的 LD+extension BED ファイルの作成
cat "$gwasLD"| awk -F '\t' -v extd=$extd '{
  print $1 "\t" $25 - extd "\t" $26 + extd "\t" $23 "\t" $24
}'| chipatlas/bin/bedtools-2.17.0/bin/bedtools intersect -v -a stdin -b "$exons"| sort -k1,1 -k2,2n| uniq| tee "$allGWAS"| awk '{
  bed = "chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/bed/GWAS:" $4 ".bed"
  print >> bed
  close(bed)
}'
cut -f1-3 "$allGWAS"| uniq > "$allGWASuniq"

# DNase-seq データのマージ
cat chipatlas/lib/inSilicoChIP/results/hg19/public/DNS.ALL.10.AllAg.AllCell.bed.*| chipatlas/bin/bedtools-2.17.0/bin/bedtools merge -i stdin > "$dhsBed"

# 各種疾患 LD-block のうち、DHS と重なるものを抽出
rm -f rm tmp/insilicoChIP_preProcessedgwas*
ql=`sh chipatlas/sh/QSUB.sh mem`
for bed in `ls "chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/bed/"*bed`; do
  outBed=`echo "$bed"| sed 's[/bed/[/ldDhsBed/['`
  echo "chipatlas/bin/bedtools-2.17.0/bin/bedtools intersect -a \"$dhsBed\" -b \"$bed\"| sort -k1,1 -k2,2n| chipatlas/bin/bedtools-2.17.0/bin/bedtools merge -i stdin > \"$outBed\""
done > tmp/insilicoChIP_preProcessedgwas
split -l 20 tmp/insilicoChIP_preProcessedgwas tmp/insilicoChIP_preProcessedgwasx

for tmp in `ls tmp/insilicoChIP_preProcessedgwasx*`; do
  cat $tmp| awk '
  BEGIN {
    print "#!/bin/sh"
    print "#$ -S /bin/sh"
  } {
    print
  }' > "$tmp"X
  qsub $ql -o /dev/null -e /dev/null -N LD-DHS "$tmp"X
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
rm -f rm tmp/insilicoChIP_qsub_gwas*
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
  titleA="tmpTiTle"
  if [ $wcl -ge 1 ]; then # 登録数が 1 以上のみ in silico ChIP をおこなう
    echo sh bin/insilicoChIP -a \"$bed\" -b \"$dhsLDuniq\" -Q 10 -A \"$titleA\" -B \"Other GWAS\" -T \"$titleA vs Other GWAS\" -v -o bed hg19 \"$outFn\"
  fi
done| awk '{print rand() "\t" $0}'| sort -k1n| cut -f2-| awk '{
  if ((NR - 1) % 10 == 0) print "#!/bin/sh\n#$ -S /bin/sh"
  print
}'| split -l 12 - tmp/insilicoChIP_qsub_gwas

for tmp in `ls tmp/insilicoChIP_qsub_gwas*`; do
  qsub $ql -o /dev/null -e /dev/null -N iscGWAS "$tmp"
done

# 公開用リストを作成
awk -F '\t' -v fn="x" '{
  if (fn != FILENAME) {
    fn = FILENAME
    N = split(fn, a, "/")
    id = a[N]
    sub(/\.bed$/, "", id)
  }
  locus = $1 "\t" $2 "\t" $3
  x[locus] = x[locus] "," id
} END {
  for (l in x) {
    sub(",", "", x[l])
    print l "\t" x[l]
  }
}' chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/ldDhsBed/*.bed| sort -k1,1 -k2,2n > chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/LD-DHSs.bed
cat "$id2name"| awk '{print "GWAS:" $0}'| tr '_' ' ' > chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/GWAS_IDs.tab

while :; do
  qN=`qstat| awk '$3 == "iscGWAS"'| wc -l`
  if [ $qN -eq 0 ]; then
    sh chipatlas/sh/analTools/preProcessed_insilicoChIP.sh P gwas $qVal hg19
    rm -f tmp/insilicoChIP_qsub_gwas*
    break
  fi
done


exit

