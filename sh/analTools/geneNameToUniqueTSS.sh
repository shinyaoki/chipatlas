#!/bin/sh
#$ -S /bin/sh

projectDir=$1

for Genome in `ls $projectDir/results/`; do
  case $Genome in
    "hg19" | "mm9" )
        curl http://hgdownload.cse.ucsc.edu/goldenPath/$Genome/database/knownCanonical.txt.gz| gunzip| awk -F '\t' '{print $0 "\tknownCanonical"}'
        # chr1  566134  566155  14  uc021oek.1  uc021oek.1  $5 と $6 はユニーク
      
        curl http://hgdownload.cse.ucsc.edu/goldenPath/$Genome/database/knownToRefSeq.txt.gz| gunzip| awk -F '\t' '{print $0 "\tknownToRefSeq"}'
        # uc002qts.2  NM_014219  $2 のみユニーク
      
        curl http://hgdownload.cse.ucsc.edu/goldenPath/$Genome/database/refFlat.txt.gz| gunzip| sort -k3| awk -F '\t' '{print $2 "\t" $4 "\t" $1 "\trefFlat"}'
        # SELPLG  NM_001206609  chr12  -  109015679  109025854  109016844  109025677  2  109015679,109025634,  109018088,109025854,  $1 も $2 もユニークでない
      ;;
    "ce10" )
        curl http://hgdownload.cse.ucsc.edu/goldenPath/ce6/database/sangerCanonical.txt.gz| gunzip| awk -F '\t' '{print $0 "\tknownCanonical"}'
        # chrII  7855746  7857530  8213  T09A5.8  T09A5.8  $5 と $6 はユニーク
        
        curl http://hgdownload.cse.ucsc.edu/goldenPath/ce6/database/sangerToRefSeq.txt.gz| gunzip| awk -F '\t' '{print $0 "\tknownToRefSeq"}'
        # T09A5.8  NM_063251  $2 のみユニーク
        
        curl http://hgdownload.cse.ucsc.edu/goldenPath/ce10/database/refFlat.txt.gz| gunzip| sort -k3| awk -F '\t' '{print $2 "\t" $4 "\t" $1 "\trefFlat"}'
        # cec-3  NM_063251  chrII  -  7856026  7857417  7856026  7857417  7  7856026,7856131,  7856088,7856248,  $1 も $2 もユニークでない
      ;;
    "dm3" )
        curl http://hgdownload.cse.ucsc.edu/goldenPath/dm3/database/flyBaseCanonical.txt.gz| gunzip| awk -F '\t' '{print $0 "\tknownCanonical"}'
        # chr2L  15039495  15043335  12137  CG3497-RA  n/a
        
        curl http://hgdownload.cse.ucsc.edu/goldenPath/dm3/database/flyBaseToRefSeq.txt.gz| gunzip| awk -F '\t' '{print $0 "\tknownToRefSeq"}'
        # CG3497-RA  NM_057520
        
        curl http://hgdownload.cse.ucsc.edu/goldenPath/dm3/database/refFlat.txt.gz| gunzip| sort -k3| awk -F '\t' '{print $2 "\t" $4 "\t" $1 "\trefFlat"}'
        # Su(H)  NM_057520  chr2L  +  15039487  15043334  15039936  15042618  4  15039487,15041094,15042033,15042306,  15040320,15041975,15042241,15043334,
      ;;
  esac| awk -F '\t' '{
    if ($7 == "knownCanonical") kcan[$5] = $0    # kcan["uc021vdj.1"] = chr1    566134  566155  14      uc021oek.1      uc021oek.1
    if ($3 == "knownToRefSeq")  ktrNM[$1] = $2   # ktrNM["uc021vdj.1"] = "NM_206894"
    if ($4 == "refFlat")        rffNM[$1] = $0   # rffNM["NM_206894"] = "NM_206894"  "+ or -" Gene Name
  } END {
    for (kn in kcan) {
      if (rffNM[ktrNM[kn]] && rffNM[ktrNM[kn]] ~ "NM_") print kcan[kn] "\t" rffNM[ktrNM[kn]]
    }
  }'| sort -k1,1 -k2,2n| awk -F '\t' '{   # ソートすることで、chr6_mcf_hap5 などを除去
    if (!a[$10]++) printf "%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $10, $9, $8
  }' > $projectDir/lib/TSS/uniqueTSS.$Genome.bed
      # chr6    31132113        31138451        POU5F1  -       NM_002701

  case $Genome in
    "sacCer3" ) # 酵母は RefSeq genes がない
        {
          curl http://hgdownload.cse.ucsc.edu/goldenPath/sacCer3/database/sgdCanonical.txt.gz| gunzip| awk -F '\t' '{print $0 "\tknownCanonical"}'
          # chrM  27665  27812  5  Q0080  P00856  $5 はユニーク
          
          curl http://hgdownload.cse.ucsc.edu/goldenPath/sacCer3/database/sgdToName.txt.gz| gunzip| awk -F '\t' '{print $0 "\tknownToRefSeq"}'
          # Q0080  ATP8  $1 と $2 はユニーク
          
          curl http://hgdownload.cse.ucsc.edu/goldenPath/sacCer3/database/sgdGene.txt.gz| gunzip| awk -F '\t' '{print $12 "\t" $4 "\t" $2 "\trefFlat"}'
          # 585  Q0080  chrM  +  27665  27812  27665  27812  1  27665,  27812,  P00856  $2 はユニーク, $12 が n/a ならば non-coding
        }| awk -F '\t' '{
          if ($7 == "knownCanonical") kcan[$5] = $0    # kcan["Q0080"] = chrM  27665  27812  5  Q0080  P00856
          if ($3 == "knownToRefSeq")  ktrNM[$1] = $2   # ktrNM["Q0080"] = "ATP8"
          if ($4 == "refFlat")        rffNM[$3] = $0   # rffNM["Q0080"] = "P00856"  "+ or -" Q0080
        } END {
          for (kn in kcan) {
            print kcan[kn] "\t" ktrNM[kn] "\t" rffNM[kn]
          }
        }'| sort -k1,1 -k2,2n| awk -F '\t' '{
          if ($6 != "n/a")  printf "%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $8, $10, $5
        }' > $projectDir/lib/TSS/uniqueTSS.$Genome.bed
      ;;
  esac
done











