# hg19
curl "ftp://ftp.ebi.ac.uk/pub/databases/genenames/new/tsv/locus_types/gene_with_protein_product.txt"| tail -n +2| awk -F '\t' '{
  gsub("\"", "", $9)
  printf "%s\t%s\n", $2, (($9)? $9 "|" : "") $3
}'| sort -f > "curationTool/lib/geneSynonyms.hg19.tab"

# mm9
curl "ftp://ftp.informatics.jax.org/pub/reports/MRK_List1.rpt"| tail -n+2| awk -F '\t' '{
  if ($6 == "+" || $6 == "-") {
    if ($1 ~ "MGI:" && $11 == "protein coding gene") {
      printf "%s\t%s\n", $7, (($12)? $12 "|" : "") $9
    }
  }
}'| sort -f > "curationTool/lib/geneSynonyms.mm9.tab"

# dm3
curl "http://flybase.org/static_pages/downloads/FB2015_04/synonyms/fb_synonym_fb_2015_04.tsv.gz"| gunzip| tail -n+7| awk -F '\t' '{
  if ($1 ~ "FBgn" && $2 !~ "\\\\") {
    gsub(",", "|", $5)
    printf "%s\t%s\n", $2, (($5)? $5 "|" : "") $3
  }
}'| sort -f > "curationTool/lib/geneSynonyms.dm3.tab"

# ce10
curl "ftp://anonymous@ftp.wormbase.org/pub/wormbase/species/c_elegans/annotation/geneOtherIDs/c_elegans.PRJNA13758.WS250.geneOtherIDs.txt.gz"| gunzip| awk -F '\t' '{
  if ($1 ~ "WBGene" && $4 && $4 !~ "21ur-" && $4 !~ "CELE_" && $4 !~ "mir-") {
    for (i=5; i<=NF; i++) {
      if ($i !~ "CELE_") a[NR] = a[NR] "|" $i
    }
    sub("\\|", "", a[NR])
    printf "%s\t%s\n", $4, a[NR]
  }
}'| sort -f > "curationTool/lib/geneSynonyms.ce10.tab"

# sacCer3
# http://yeastmine.yeastgenome.org/yeastmine/bagDetails.do?scope=all&bagName=ALL_Verified_Uncharacterized_Dubious_ORFs
cat "/Users/Oki/Downloads/results-3.tsv"| awk -F '\t' '{
  if ($4 !~ "\"") {
    a[NR] = $6 "|" $5
    
    printf "%s\t%s\n", $4, a[NR]
  }
}'| sed 's/""|""//g' | sed 's/""|//g' | sed 's/|""//g'| sort -f > "curationTool/lib/geneSynonyms.sacCer3.tab"
