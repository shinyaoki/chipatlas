#!/bin/sh
#$ -S /bin/sh

# qsub chipatlas/sh/analTools/iscF5Enh.sh

id2name="chipatlas/results/hg19/insilicoChIP_preProcessed/fantomEnhancer/lib/ff5id2name.tab"
bedB="chipatlas/results/hg19/insilicoChIP_preProcessed/fantomEnhancer/lib/differentially_expressed_enhancers_uniq.bed"
qVal=5

mkdir -p chipatlas/results/hg19/insilicoChIP_preProcessed/fantomEnhancer/lib
mkdir -p chipatlas/results/hg19/insilicoChIP_preProcessed/fantomEnhancer/bed
mkdir -p chipatlas/results/hg19/insilicoChIP_preProcessed/fantomEnhancer/results/tsv

##########################################################################################################################################################################
#                                                                         FANTOM Enhancer
##########################################################################################################################################################################

# 細胞名とその ID の対応表のダウンロードと整形
{
  for list in Cell_Ontology_terms_list Human_Disease_Ontology_terms_list Uber_Anatomy_Ontology_terms_list; do
    curl "http://fantom.gsc.riken.jp/5/sstar/$list"| awk -F '\"' '{
      if ($1 ~ /td data-sort-value=$/) {
        printf "%s\t", $8
        getline
        print $3
      }
    }'| tr -d '>'| tr '<' '\t'| cut -f1-2| tr '/' '|'
  done
  
  idfn=`curl "http://fantom.gsc.riken.jp/5/datafiles/phase2.0/extra/Ontology/"| grep "obo.txt"| head -n1| tr '""' '\t\t'| cut -f8`
  if [ "$idfn" = "" ]; then
    idfn="ff-phase2-140729.obo.txt"
  fi
  curl "http://fantom.gsc.riken.jp/5/datafiles/phase2.0/extra/Ontology/""$idfn"| awk '{
    if ($1 == "id:" && ($2 ~ "CL:" || $2 ~ "DOID:" || $2 ~ "UBERON:")) {
      printf $2
      getline
      sub("name: ", "", $0)
      print "\t" $0
    }
  }'
}| awk '!a[$1]++' > "$id2name"
  # CL:0000077      mesothelial cell

# facet_differentially_expressed_enhancers の DL
curl "http://enhancer.binf.ku.dk/presets/facet_differentially_expressed_0.05.tgz" > facet_differentially_expressed_0.05.tgz
cd chipatlas/results/hg19/insilicoChIP_preProcessed/fantomEnhancer/bed
tar zxvf ~/facet_differentially_expressed_0.05.tgz
cd
rm facet_differentially_expressed_0.05.tgz
mv chipatlas/results/hg19/insilicoChIP_preProcessed/fantomEnhancer/bed/0_05/* chipatlas/results/hg19/insilicoChIP_preProcessed/fantomEnhancer/bed/
rm -r chipatlas/results/hg19/insilicoChIP_preProcessed/fantomEnhancer/bed/0_05


# Fantom enhancer の BED 名を ID のみに変える
cd chipatlas/results/hg19/insilicoChIP_preProcessed/fantomEnhancer/bed
for bed in `ls *bed`; do
  newFn=`echo $bed| cut -d '_' -f1`".bed"
  cut -f1-3 "$bed"| sort -k1,1 -k2,2n| uniq > "$newFn"
  rm "$bed"
done
cd
#####################################################################################
## 注意: Fantom enhancer の facet 名は、正式でないものがある
#####################################################################################
# ID              正式名称                         Fantom enhancer
# CL:0002327      mammary gland epithelial cell   mammary epithelial cell
# CL:0000188      cell of skeletal muscle         skeletal muscle cell
# CL:0000746      cardiac muscle cell             cardiac myocyte
# UBERON:0001044  saliva-secreting gland          salivary gland


# facet_differentially_expressed_enhancers をまとめる  # 重複する領域を削除 (重要!!!!)
cat chipatlas/results/hg19/insilicoChIP_preProcessed/fantomEnhancer/bed/*.bed| sort -k1,1 -k2,2n| uniq > "$bedB"


# in silico ChIP の実行
ql=`sh chipatlas/sh/QSUB.sh mem`
for bedA in `ls chipatlas/results/hg19/insilicoChIP_preProcessed/fantomEnhancer/bed/*.bed`; do
  id=`basename $bedA| sed 's/\.bed//'`
  titleA="tmpTiTle"
  outFn=`echo "$bedA"| sed 's[/bed/[/results/tsv/['| sed 's/\.bed$//'`
  qsub $ql -o /dev/null -e /dev/null -N "iscF5Enh" bin/insilicoChIP -a "$bedA" -b "$bedB" -Q 10 -A "$titleA" -B "Other enhancers" -T "$titleA vs Other enhancers" -v -o bed hg19 "$outFn"
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
}' chipatlas/results/hg19/insilicoChIP_preProcessed/fantomEnhancer/bed/*bed| sort -k1,1 -k2,2n > chipatlas/results/hg19/insilicoChIP_preProcessed/fantomEnhancer/lib/tissue_specific_enhancers.bed


while :; do
  qN=`qstat| awk '$3 == "iscF5Enh"'| wc -l`
  if [ $qN -eq 0 ]; then
    sh chipatlas/sh/analTools/preProcessed_insilicoChIP.sh P fantomEnhancer $qVal hg19
    break
  fi
done

exit

