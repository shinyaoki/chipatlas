#!/bin/sh
#$ -S /bin/sh

# sh chipatlas/sh/analTools/fantomDataAnalysis.sh

mkdir -p chipatlas/results/hg19/fantomEnhancer
mkdir -p chipatlas/results/hg19/fantomPromoter
mkdir -p chipatlas/results/mm9/fantomPromoter
mkdir -p chipatlas/lib/fantom/fantomEnhancer/bed


id2name="chipatlas/lib/fantom/id2name.tab"


# 細胞名とその ID の対応表のダウンロードと整形
for list in Cell_Ontology_terms_list Human_Disease_Ontology_terms_list Uber_Anatomy_Ontology_terms_list; do
curl "http://fantom.gsc.riken.jp/5/sstar/$list"| awk -F '\"' '{
  if ($1 ~ /td data-sort-value=$/) {
    printf "%s\t", $8
    getline
    print $3
  }
}'| tr -d '>'| tr '<' '\t'| cut -f1-2| tr '/' '|'
done > "$id2name"
  # CL:0000077      mesothelial cell


# facet_differentially_expressed_enhancers の DL
curl http://enhancer.binf.ku.dk/presets/facet_differentially_expressed_0.05.tgz > facet_differentially_expressed_0.05.tgz
cd chipatlas/lib/fantom
tar zxvf ~/facet_differentially_expressed_0.05.tgz
cd
rm facet_differentially_expressed_0.05.tgz
mv chipatlas/lib/fantom/0_05/* chipatlas/lib/fantom/fantomEnhancer/bed
rm -r chipatlas/lib/fantom/0_05


ls chipatlas/lib/fantom/fantomEnhancer/bed/*bed| awk -F '\t' -v id2name="$id2name" '
BEGIN {
  while ((getline < id2name) > 0) {     # Fantom enhancer の facet 名を正式名称に変える
    gsub(" ", "_", $2)
    x[$1] = $2          # x[UBERON:0002106] = spleen
  }
} {
  split($1, f, "/")     # f[6] = UBERON:0002106_spleen_differentially_expressed_enhancers.bed
  split(f[6], i, "_")   # i[1] = UBERON:0002106
  print "mv " $1 " chipatlas/lib/fantom/fantomEnhancer/bed/" i[1] "_" x[i[1]] "_differentially_expressed_enhancers.bed"
}'| sh
#####################################################################################
## 注意: Fantom enhancer の facet 名は、正式でないものがある
#####################################################################################
# ID              正式名称                         Fantom enhancer
# CL:0002327      mammary gland epithelial cell   mammary epithelial cell
# CL:0000188      cell of skeletal muscle         skeletal muscle cell
# CL:0000746      cardiac muscle cell             cardiac myocyte
# UBERON:0001044  saliva-secreting gland          salivary gland







