#!/bin/sh
#$ -S /bin/sh

# qsub chipatlas/sh/analTools/insilicoChIP_FantomPromoter.sh hg19

genome=$1
id2name="chipatlas/results/$genome/insilicoChIP_preProcessed/fantomPromoter/lib/ff5id2name.tab"
qVal=5

mkdir -p chipatlas/results/$genome/insilicoChIP_preProcessed/fantomPromoter/lib
mkdir -p chipatlas/results/$genome/insilicoChIP_preProcessed/fantomPromoter/geneList
mkdir -p chipatlas/results/$genome/insilicoChIP_preProcessed/fantomPromoter/results/tsv

##########################################################################################################################################################################
#                                                                         FANTOM Promoter
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


# promoter と gene symbol のダウンロードと整形
p2g="chipatlas/results/$genome/insilicoChIP_preProcessed/fantomPromoter/lib/promoter2geneSymbols.bed"
case $genome in
  "hg19" ) org=human;;
  "mm9" )  org=mouse;;
esac
curl "http://fantom.gsc.riken.jp/5/datafiles/phase1.3/extra/TSS_classifier/TSS_"$org".bed.gz"| gunzip| tr '@,' '\t\t'| awk -F '\t' -v OFS='\t' '{
  if ($4 != "p") print $1, $2, $3, $5, $4, $8
}' > "$p2g"  # chr10   101621605       101621610       Mgat4c  p18     +

# 細胞特異的プロモータリストのダウンロードと整形
urlHead="http://fantom.gsc.riken.jp/5/datafiles/phase1.3/extra/Sample_ontology_enrichment_of_CAGE_peaks/"
curl "$urlHead""$genome""exp_cell_types_general_term_excluded.txt.gz"| gunzip > chipatlas/results/$genome/insilicoChIP_preProcessed/fantomPromoter/lib/specificPromoters.CL.txt
curl "$urlHead""$genome""exp_disease_general_term_excluded.txt.gz"| gunzip > chipatlas/results/$genome/insilicoChIP_preProcessed/fantomPromoter/lib/specificPromoters.DOID.txt
curl "$urlHead""$genome""exp_uberon_general_term_excluded.txt.gz"| gunzip > chipatlas/results/$genome/insilicoChIP_preProcessed/fantomPromoter/lib/specificPromoters.UBERON.txt
# chr10:100993894..100993906,-    CL:0000097[p.value=7.36e-45,n=5];CL:0002028[p.value=7.36e-45,n=5];CL:0000163[p.value=2.47e-25,n=9];CL:0000151[p.value=7.52e-07,n=36]

# 細胞特異的 gene list の作成
geneListDir="chipatlas/results/"$genome"/insilicoChIP_preProcessed/fantomPromoter/geneList"
for class in CL DOID UBERON; do
  cat "chipatlas/results/$genome/insilicoChIP_preProcessed/fantomPromoter/lib/specificPromoters.$class.txt"| tr ';' '\t'| awk -F '\t' -v OFS='\t' -v p2g="$p2g" '
  BEGIN {
    while ((getline < p2g) > 0) a[$1 ":" $2 ".." $3 "," $6] = $4
  } {
    for (i=2; i<=NF; i++) print a[$1], $i
  }'| tr '[' '\t'| awk -F '\t' -v OFS='\t' '{
    if ($2 != "NA" && $1 != "" && $2 != "") print $1, $2
  }'| sort| uniq| awk -F '\t' -v geneListDir="$geneListDir" -v OFS='\t' '{
    fn = geneListDir "/" $2 ".geneList.txt"
    print $1 >> fn
    close(fn)
  }'
done


# in silico ChIP の実行
up=5000
down=5000
ql=`sh chipatlas/sh/QSUB.sh mem`
for geneList in `ls "$geneListDir"/*.geneList.txt`; do
  id=`basename $geneList| cut -d '.' -f1`
  titleA=`cat $id2name| awk -F '\t' -v id="$id" '$1 == id {printf $2}'| sed 's/\(.\)\(.*\)/\U\1\L\2/g'`
  titleB="Other RefSeq genes"
  outfn="chipatlas/results/$genome/insilicoChIP_preProcessed/fantomPromoter/results/tsv/"$id
  qsub $ql -o /dev/null -e /dev/null -N $genome"Prom" bin/insilicoChIP -a "$geneList" -A "$titleA" -B "$titleB" -T "$titleA vs $titleB" -o -u $up -d $down gene "$genome" "$outfn"
done


# 公開用リストを作成
awk -F '\t' -v fn="x" '{
  if (fn != FILENAME) {
    fn = FILENAME
    N = split(fn, a, "/")
    id = a[N]
    sub(/\.geneList.txt$/, "", id)
  }
  locus = $1
  x[locus] = x[locus] "," id
} END {
  for (l in x) {
    sub(",", "", x[l])
    print l "\t" x[l]
  }
}' chipatlas/results/$genome/insilicoChIP_preProcessed/fantomPromoter/geneList/*.geneList.txt| sort > chipatlas/results/$genome/insilicoChIP_preProcessed/fantomPromoter/lib/tissue_specific_genes.txt


while :; do
  qN=`qstat| awk -v jb=$genome"Prom" '$3 == jb'| wc -l`
  if [ $qN -eq 0 ]; then
    sh chipatlas/sh/analTools/preProcessed_insilicoChIP.sh P fantomPromoter $qVal $genome $up $down
    break
  fi
done

exit

