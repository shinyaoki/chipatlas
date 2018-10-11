# hg19
curl "ftp://ftp.ebi.ac.uk/pub/databases/genenames/new/tsv/locus_types/gene_with_protein_product.txt"| tail -n +2| awk -F '\t' '{
  gsub("\"", "", $9)
  printf "%s\t%s\n", $2, (($9)? $9 "|" : "") $3
}'| sort -f > "chipatlas/sh/curationTool/lib/geneSynonyms.hg19.tab"

# mm9
curl "ftp://ftp.informatics.jax.org/pub/reports/MRK_List1.rpt"| tail -n+2| awk -F '\t' '{
  if ($6 == "+" || $6 == "-") {
    if ($1 ~ "MGI:" && $11 == "protein coding gene") {
      printf "%s\t%s\n", $7, (($12)? $12 "|" : "") $9
    }
  }
}'| sort -f > "chipatlas/sh/curationTool/lib/geneSynonyms.mm9.tab"

# rn6
curl "ftp://ftp.rgd.mcw.edu/pub//data_release/GENES_RAT.txt"| awk '$1 ~ "GENE_RGD_ID" , 0'| tail -n+2| awk -F '\t' 'length($2) > 0 && $37 == "protein-coding" {
  printf $2
  N = split("29,30,3,31", a, ",")
  for (i=1; i<=N; i++) if (length($a[i]) > 0) printf "\t" $a[i]
  printf "\n"
}'| tr ';' '\t'| awk -F '\t' '{
  for (i=2; i<NF; i++) if ($1 != $i) print $1 "\t" $i
}'| sort| uniq| awk -F '\t' '{
  x[$1] = x[$1] "|" $2
} END {
  for (gene in x) {
    sub("\\|", "", x[gene])
    print gene "\t" x[gene]
  }
}'| sort -f > "chipatlas/sh/curationTool/lib/geneSynonyms.rn6.tab"
  
# dm3
curl "http://flybase.org/static_pages/downloads/FB2015_04/synonyms/fb_synonym_fb_2015_04.tsv.gz"| gunzip| tail -n+7| awk -F '\t' '{
  if ($1 ~ "FBgn" && $2 !~ "\\\\") {
    gsub(",", "|", $5)
    printf "%s\t%s\n", $2, (($5)? $5 "|" : "") $3
  }
}'| sort -f > "chipatlas/sh/curationTool/lib/geneSynonyms.dm3.tab"

# ce10
curl "ftp://anonymous@ftp.wormbase.org/pub/wormbase/species/c_elegans/annotation/geneOtherIDs/c_elegans.PRJNA13758.WS250.geneOtherIDs.txt.gz"| gunzip| awk -F '\t' '{
  if ($1 ~ "WBGene" && $4 && $4 !~ "21ur-" && $4 !~ "CELE_" && $4 !~ "mir-") {
    for (i=5; i<=NF; i++) {
      if ($i !~ "CELE_") a[NR] = a[NR] "|" $i
    }
    sub("\\|", "", a[NR])
    printf "%s\t%s\n", $4, a[NR]
  }
}'| sort -f > "chipatlas/sh/curationTool/lib/geneSynonyms.ce10.tab"

# sacCer3
# http://yeastmine.yeastgenome.org/yeastmine/bagDetails.do?scope=all&bagName=ALL_Verified_Uncharacterized_Dubious_ORFs
cat "/Users/Oki/Downloads/results-3.tsv"| awk -F '\t' '{
  if ($4 !~ "\"") {
    a[NR] = $6 "|" $5
    
    printf "%s\t%s\n", $4, a[NR]
  }
}'| sed 's/""|""//g' | sed 's/""|//g' | sed 's/|""//g'| sort -f > "chipatlas/sh/curationTool/lib/geneSynonyms.sacCer3.tab"
