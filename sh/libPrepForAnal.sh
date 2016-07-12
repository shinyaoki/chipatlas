#!/bin/sh
#$ -S /bin/sh

# qsub -o /dev/null -e /dev/null -pe def_slot 4 chipatlas/sh/libPrepForAnal.sh chipatlas
projectDir=$1


####################################################################################################################################
#                                                protein-coding 遺伝子リストの作成
####################################################################################################################################
rm -rf $projectDir/lib/geneList
mkdir $projectDir/lib/geneList
rm -f keyForStringFiltering

for Genome in `ls $projectDir/results`; do
  case $Genome in
    hg19)
      echo -e "$Genome\tBioMart_HUGO" >> keyForStringFiltering
      curl ftp://ftp.ebi.ac.uk/pub/databases/genenames/new/tsv/locus_types/gene_with_protein_product.txt| awk -F '\t' '{
        if (NR > 1) print $2
      }'
    ;;
    mm9)
      echo -e "$Genome\tEnsembl_MGI" >> keyForStringFiltering
      curl ftp://ftp.informatics.jax.org/pub/reports/MRK_List1.rpt| awk -F '\t' '{
        if (NR > 1 && $11 == "protein coding gene") print $7
      }'
    ;;
    dm3)
      echo -e "$Genome\tFlyBase" >> keyForStringFiltering
      gtfVersion=`curl ftp://ftp.flybase.net/genomes/Drosophila_melanogaster/current/gtf/md5sum.txt| awk '{printf "%s", $2}'`
      curl ftp://ftp.flybase.net/genomes/Drosophila_melanogaster/current/gtf/$gtfVersion| gunzip| awk -F '\t' '{
        if ($3 == "CDS") {
          split($9, a, "\"")
          print a[4]
        }
      }'
    ;;
    ce10)
      echo -e "$Genome\tWormBase" >> keyForStringFiltering
      curl ftp://ftp.wormbase.org/pub/wormbase/releases/WS230/species/c_elegans/c_elegans.WS230.protein.fa.gz| gunzip| awk -F '\t' '{
        if ($1 ~ ">" && $4 ~ "locus:") {
          split($4, a, ":")
          print a[2]
        }
      }'
    ;;
    sacCer3)
      echo -e "$Genome\tEnsembl_SGD" >> keyForStringFiltering
      curl http://downloads.yeastgenome.org/sequence/S288C_reference/orf_protein/orf_trans.fasta.gz| gunzip| awk '{
        if ($1 ~ ">") print $2
      }'
    ;;
  esac| sort| uniq > $projectDir/lib/geneList/$Genome.txt
done


####################################################################################################################################
#                                                refFlat より、TSSリストを作成
####################################################################################################################################
for Genome in `ls $projectDir/results`; do
  if [ $Genome != "sacCer3" ]; then
    curl http://hgdownload.cse.ucsc.edu/goldenPath/$Genome/database/refFlat.txt.gz| gunzip| awk -F '\t' '{
      if ($4 == "+") TSS = $5
      else           TSS = $6
      printf "%s\t%s\t%s\t%s\n", $3, TSS, $1, $2
    }'
  else # sacCer3 は refFlat がないので、xenoRefFlat を使い、geneList と一致するものだけを抽出
    geneList=$projectDir/lib/geneList/$Genome.txt
    curl http://hgdownload.cse.ucsc.edu/goldenPath/sacCer3/database/xenoRefFlat.txt.gz| gunzip| awk -F '\t' -v geneList=$geneList '
    BEGIN {
      while ((getline < geneList) > 0) g[$1]++
    } {
      if ($4 == "+") TSS = $5
      else           TSS = $6
      if (g[$1] > 0) printf "%s\t%s\t%s\t%s\n", $3, TSS, $1, $2 # Chr  TSS  geneName  NM or NR
    }'
  fi|\
  # 同じ遺伝子で同じ TSS を除去
  awk '!a[$1, $2, $3]++'|\
  # haplotype chromosomes を除去
  awk '$1 !~ "_hap"'|\
  awk -F '\t' '{printf "%s\t%s\t%s\t%s\t%s\n", $1, $2, $2, $3, $4}' > $projectDir/lib/TSS/TSS.$Genome.bed
done

####################################################################################################################################
#                                                unique TSSリストを作成
####################################################################################################################################

sh $projectDir/sh/analTools/geneNameToUniqueTSS.sh $projectDir

####################################################################################################################################
#                                                STRING データの収集
####################################################################################################################################
stringDir=$projectDir/lib/string
homeDir=`pwd`
rm -rf $stringDir
mkdir $stringDir
mkdir $projectDir/lib/TSS
mv keyForStringFiltering $stringDir/keyForStringFiltering.tab
cd $stringDir

curl http://string-db.org/newstring_download/protein.aliases.v10.txt.gz| gunzip| sed 's/\./\!/'| tr '!' '\t'| awk -F '\t' '{
  print $1 "\t" $1 "." $2 "\t" $3 "\t" $4
}' > protein.aliases.v10.txt

curl http://string-db.org/newstring_download/species.v10.txt > species.v10.txt

# curl http://string.uzh.ch/download/protected/string_10/protein.links.full.v10.txt.gz| gunzip > protein.links.full.v10.txt
# curl http://string-db.org/newstring_download/protein.links.detailed.v10.txt.gz| gunzip > protein.links.detailed.v10.txt
# curl http://string-db.org/newstring_download/protein.links.v10.txt.gz| gunzip > protein.links.v10.txt
# curl http://string-db.org/newstring_download/protein.sequences.v10.fa.gz| gunzip > protein.sequences.v10.fa

# 生物種と ID の対応付け
cat ~/$projectDir/sh/preferences.txt| awk -F '\t' -v projectDir=$projectDir -v homeDir=$homeDir '{
  if ($1 == "Genome") {
    N = split($2, sp, " ")
    for (i=1; i<=N; i++) {
      gsub("_", " ", sp[i])
      split(sp[i], a, "=")
      g[a[1]] = a[2]      # g["hg19"] = "Homo sapiens"
      org[a[2]] = a[1]    # org["Homo sapiens"] = "hg19"
    }
    while ((getline < "species.v10.txt") > 0) {
      if (org[$3]) gid[$1] = org[$3]    # gid["9606"] = "hg19"
    }
    for (key in gid) print key "\t" gid[key] >> "genomeID.tab"
    for (key in g) {  # geneList に含まれる遺伝子を抽出
      geneList = homeDir "/" projectDir "/lib/geneList/" key ".txt"
      while ((getline < geneList) > 0) {
        gene[$1,key]++    # gene["POU5F1","hg19"]
      }
    }
    while ((getline < "protein.aliases.v10.txt") > 0) {   # protein.aliases.v10 を生物種で分ける
      if(gene[$3,gid[$1]]) {
        sub("\\.", SUBSEP, $2)  # $1 = 9606<SUBSEP>ENSP00000259915
        print $2 "\t" $3 "\t" $4 >> "protein.aliases.v10." gid[$1] ".tmp" # けっこうメモリを消費する
      }
    }
  }
}'

# 重複する ID を除く
for Genome in `ls ~/$projectDir/results`; do
  Filter=`cat keyForStringFiltering.tab| grep $Genome| cut -f2`
  cat protein.aliases.v10.$Genome.tmp| awk -F '\t' -v Filter=$Filter '{
    if (tolower($3) !~ "synonym" && $3 ~ Filter) {  # Synonym を除き、Filter にマッチするものを残す
      x[$1] = $2
      n[$1]++                                       # それでも重複するものは削除
    }
  } END {
    for (key in x) if (n[key] == 1) print key "\t" x[key]   # 9606<SUBSEP>ENSP00000259915   POU5F1
  }' > protein.aliases.v10.$Genome.txt
  rm protein.aliases.v10.$Genome.tmp
done



# protein.actions.v10 を生物種で分ける
curl http://string-db.org/newstring_download/protein.actions.v10.txt.gz| gunzip| tee protein.actions.v10.txt| awk -F '\t' '
BEGIN {
  while ((getline < "genomeID.tab") > 0) {
    gid[$1] = $2   # gid["9606"] = "hg19"
  }
  close("genomeID.tab")
  
  for (key in gid) {
    fn = "protein.aliases.v10." gid[key] ".txt"
    while ((getline < fn) > 0) {
      Prot[$1] = $2   # Prot[9606<SUBSEP>ENSP00000259915] = POU5F1
    }
    close(fn)
  }
} {
  sub("\\.", SUBSEP, $1)  # $1 = 9606<SUBSEP>ENSP00000259915
  sub("\\.", SUBSEP, $2)  # $2 = 9607<SUBSEP>ENSP00000259917
  split($1, a, SUBSEP)    # a[1] = 9606, a[2] = ENSP00000259915
  split($2, b, SUBSEP)    # b[1] = 9607, b[2] = ENSP00000259917
  if (a[1] == b[1] && Prot[$1] && Prot[$2]) print Prot[$1] "\t" Prot[$2] "\t" $3 "\t" $4 "\t" $5 "\t" $6 >> "protein.actions.v10." gid[a[1]] ".txt"
}'    # POU5F1    NANOG   expression    inhibition    0/1   360

exit
# protein.links.detailed.v10 を生物種で分ける
curl http://string-db.org/newstring_download/protein.links.detailed.v10.txt.gz| gunzip| tee protein.links.detailed.v10.txt| awk -F '\t' '
BEGIN {
  while ((getline < "genomeID.tab") > 0) {
    gid[$1] = $2   # gid["9606"] = "hg19"
  }
  close("genomeID.tab")
  
  for (key in gid) {
    fn = "protein.aliases.v10." gid[key] ".txt"
    while ((getline < fn) > 0) {
      Prot[$1] = $2   # Prot[9606<SUBSEP>ENSP00000259915] = POU5F1
    }
    close(fn)
  }
  FS = " "
} {
  sub("\\.", SUBSEP, $1)  # $1 = 9606<SUBSEP>ENSP00000259915
  sub("\\.", SUBSEP, $2)  # $2 = 9607<SUBSEP>ENSP00000259917
  split($1, a, SUBSEP)    # a[1] = 9606, a[2] = ENSP00000259915
  split($2, b, SUBSEP)    # b[1] = 9607, b[2] = ENSP00000259917
  if (a[1] == b[1] && Prot[$1] && Prot[$2]) {
    print Prot[$1] "\t" Prot[$2] "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $9 "\t" $10 >> "protein.links.detailed.v10." gid[a[1]] ".txt"
  }
}'    # POU5F1    NANOG    0   0   0   223   0   0   328   456


############################################################################################################################################
##    以下、ファイル内容
############################################################################################################################################

====> protein.actions.v10.txt <==== # タブ区切り
item_id_a									item_id_b									mode				action			a_is_acting		score
9606.ENSP00000259915			9606.ENSP00000259915			activation	activation	0	800
10090.ENSMUSP00000104411	10090.ENSMUSP00000039653	expression	inhibition	1	160
# $3 (mode) = binding expression catalysis reaction activation inhibition ptmod
# $4 (action) = 値なし inhibition activation
# $5 (a_is_acting) = 0 1
# $6 (score) = 0 - 1000

# $3 〜 $5 の組み合わせ
# mode			action			a_is_acting
activation	activation	0
activation	activation	1
inhibition	inhibition	0
inhibition	inhibition	1
binding			値なし			 0
binding			値なし			 1
binding			activation	0
binding			activation	1
binding			inhibition	0
binding			inhibition	1
expression	値なし			 0  # A -> B (発現活性化)
expression	値なし			 1  # A <- B (発現活性化)
expression	inhibition	0  # A -| B (発現抑制)
expression	inhibition	1  # A |- B (発現抑制)
catalysis		値なし			 0
catalysis		値なし			 1
ptmod				値なし			 0
ptmod				値なし			 1
reaction		値なし			 0
reaction		値なし			 1


====> protein.aliases.v10.txt <==== # タブ区切り
species_ncbi_taxon_id  protein_id alias   source
9606	9606.ENSP00000259915			POU5F1	BioMart_HUGO
10090	10090.ENSMUSP00000039653	Nodal		BLAST_KEGG_NAME

====> species.v10.txt <==== # タブ区切り
## taxon_id	STRING_type	STRING_name_compact	official_name_NCBI
9606	core	Homo sapiens	Homo sapiens
10090	core	Mus musculus	Mus musculus
6239	core	Caenorhabditis elegans	Caenorhabditis elegans
7227	core	Drosophila melanogaster	Drosophila melanogaster
4932	core	Saccharomyces cerevisiae	Saccharomyces cerevisiae



## 以下は不要か??? ##############################################

====> protein.links.detailed.v10.txt <==== # スペース区切り
protein1             protein2             neighborhood fusion "cooccurence" coexpression experimental database textmining combined_score
9606.ENSP00000219593 9606.ENSP00000259915 0 0 0 223 0 0 328 456
9606.ENSP00000259915 9606.ENSP00000000442 0 0 0 0 149 0 510 565
# $3 以降 0 - 1000
# 仲木さんは タンパク質間相互作用の尤度として $5 (cooccurence) > 500 を使用

====> protein.links.v10.txt <==== # スペース区切り
protein1         protein2         combined_score
394.NGR_c00010   394.NGR_c00020   522
394.NGR_c00010   394.NGR_c00030   522
# $3 0 - 1000

====> protein.sequences.v10.fa <====
>394.NGR_c00010 (Sinorhizobium fredii NGR234)
MRHDALFERVSARLKAQVGPDVFASWFGRLKLHSVSKSVVRLSVPTTFLKSWINNRYLELITSLFQQEDGEILKVEILVR
TATRGQRPAVHEEAVAAAAEPAAAAPVRRAASPQPVAAAAATVAASAKPVQAPLFGSPLDQRYNFESFVEGSSNRVALAA
