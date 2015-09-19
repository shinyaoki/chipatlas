mkdir string
cd string

curl http://string-db.org/newstring_download/protein.actions.v10.txt.gz| gunzip > protein.actions.v10.txt
curl http://string-db.org/newstring_download/protein.aliases.v10.txt.gz| gunzip > protein.aliases.v10.txt
curl http://string-db.org/newstring_download/species.v10.txt > species.v10.txt
# curl http://string.uzh.ch/download/protected/string_10/protein.links.full.v10.txt.gz| gunzip > protein.links.full.v10.txt
# curl http://string-db.org/newstring_download/protein.links.detailed.v10.txt.gz| gunzip > protein.links.detailed.v10.txt
# curl http://string-db.org/newstring_download/protein.links.v10.txt.gz| gunzip > protein.links.v10.txt
# curl http://string-db.org/newstring_download/protein.sequences.v10.fa.gz| gunzip > protein.sequences.v10.fa



projectDir=xhipome_ver3
# 生物種と ID の対応付け
cat ~/$projectDir/sh/preferences.txt| awk -F '\t' '{
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
    for (key in g) {  # refFlat に含まれる遺伝子を抽出
      curlcmd = "curl http://hgdownload.cse.ucsc.edu/goldenPath/" key "/database/refFlat.txt.gz| gunzip" # sacCer3 は不可能
      while ((curlcmd | getline var) > 0) {
        split(var, x, "\t")
        gene[x[1],key]++
      }
    }
    while ((getline < "protein.aliases.v10.txt") > 0) {   # protein.aliases.v10 を生物種で分ける
      if(gene[$3,gid[$1]]) print >> "protein.aliases.v10." gid[$1] ".txt" # けっこうメモリを消費する
    }
  }
}'


# protein.actions.v10 を生物種で分ける
cat protein.actions.v10.txt| awk -F '\t' '
BEGIN {
  while ((getline < "genomeID.tab") > 0) {
    gid[$1] = $2   # gid["9606"] = "hg19"
  }
  close("genomeID.tab")
  
  for (key in gid) {
    fn = "protein.aliases.v10." gid[key] ".txt"
    while ((getline < fn) > 0) {
      Prot[$1,$2] = $3
    }
    close(fn)
  }
} {
  sub("\\.", SUBSEP, $1)
  sub("\\.", SUBSEP, $2)
  split($1, a, SUBSEP)
  split($2, b, SUBSEP)
  if (a[1] == b[1] && Prot[$1] && Prot[$2]) print Prot[$1] "\t" Prot[$2] "\t" $3 "\t" $4 "\t" $5 "\t" $6 >> "protein.actions.v10." gid[a[1]] ".txt"
}'



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
9606	ENSP00000259915			POU5F1	BioMart_HUGO
10090	ENSMUSP00000039653	Nodal		BLAST_KEGG_NAME BLAST_UniProt_GN Ensembl_EntrezGene Ensembl_IKMCs_ES_cells_available Ensembl_MGI Ensembl_UniProt_GN Ensembl_WikiGene

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

