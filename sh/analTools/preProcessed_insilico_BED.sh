#!/bin/sh
#$ -S /bin/sh

# preProcessed_insilico_BED.sh
dir="$1"
mode="$2"
up="$3"
down="$4"
width="$3"

gwasCatalog="chipatlas/results/hg19/insiicoChIP_preProcessed/lib/gwasCatalog_original.bed"
bnDir=`basename "$dir"`

if [ $mode = "gwas" ]; then  # GWAS と overlap する BED ファイルを 整形する
  awk -v width=$width -v OFS='\t' -v gwasCatalog="$gwasCatalog" '
  BEGIN {
    while ((getline < gwasCatalog) > 0) a[$1, $2, $3] = $4
  } {
    ofn = FILENAME "tmp"
    print $1, $2+width, $2+width+1, $4, a[$1, $2+width, $2+width+1] >> ofn
    close(ofn)
  }' "$dir/"*.bed
  for bed in `ls "$dir/"*.bed`; do
    sort -k1,1 -k2,2n $bed"tmp"| uniq > $bed  # chr12   115836521       115836522       CTCF_@SRX199886   rs1292011
    rm $bed"tmp"
  done
  
elif [ $mode = "enhancer" ]; then  # FANTOM enhancer と overlap する BED ファイルを 整形する
  for bed in `ls "$dir/"*.bed`; do
    sort -k1,1 -k2,2n "$bed"| uniq > $bed"tmp"  # chr12   115836521       115836522       CTCF_@SRX199886
    mv $bed"tmp" "$bed"
  done

elif [ $mode = "promoter" ]; then  # overlap する BED ファイルを 整形する
  genome=`echo "$dir"| cut -d '/' -f3`
  tss="chipatlas/lib/TSS/uniqueTSS."$genome".bed"
  awk -v up=$up -v down=$down -v OFS='\t' -v tss="$tss" -F '\t' '
  BEGIN {
    while ((getline < tss) > 0) {
      beg = ($5 == "+")? $2 - up : $3 - down
      end = ($5 == "+")? $2 + down : $3 + up
      b[$1, beg, end] = $4  # g[chr15, 67348194, 67368194] = MEF2B
      a[$1, beg, end] = ($5 == "+")? $1 "\t" $2 "\t" $2+1 : $1 "\t" $3-1 "\t" $3  # g[chr1, 1269844, 1269845] = TAS1R3
      c[$1, beg, end] = t[$1, beg, end] "\t" $6 "\t" $5
    }
  } {
    ofn = FILENAME "tmp"
    print a[$1, $2, $3], $4, b[$1, $2, $3], c[$1, $2, $3] >> ofn
    close(ofn)
  }' "$dir/"*.bed
  for bed in `ls "$dir/"*.bed`; do
    sort -k1,1 -k2,2n $bed"tmp"| uniq > $bed  # chr21  45138977  45138978  SP1_@SRX100550  PDXK  NM_003681   +
    rm $bed"tmp"
  done
fi

# BED ファイルを圧縮する
cd "$dir"
cd ../
zip -r "$bnDir".zip "$bnDir"
rm -r "$bnDir"
