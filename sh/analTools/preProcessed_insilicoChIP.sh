#!/bin/sh
#$ -S /bin/sh

# qsub chipatlas/sh/analTools/preProcessed_insilicoChIP.sh

geneBody="chipatlas/results/hg19/insiicoChIP_preProcessed/lib/hg19_allGeneBody.bed"
gwasCatalog="chipatlas/results/hg19/insiicoChIP_preProcessed/lib/gwasCatalog_original.bed"
allGWAS="chipatlas/results/hg19/insiicoChIP_preProcessed/lib/allGWASfor_insilicoChIP.bed"
id2name="chipatlas/results/hg19/insiicoChIP_preProcessed/lib/ff5id2name.tab"
rm -rf chipatlas/results/hg19/insiicoChIP_preProcessed
rm -rf chipatlas/results/mm9/insiicoChIP_preProcessed
mkdir -p chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/bed
mkdir -p chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/results
mkdir -p chipatlas/results/hg19/insiicoChIP_preProcessed/fantomPromoter/geneList
mkdir -p chipatlas/results/hg19/insiicoChIP_preProcessed/fantomPromoter/results
mkdir -p chipatlas/results/hg19/insiicoChIP_preProcessed/gwas/bed
mkdir -p chipatlas/results/hg19/insiicoChIP_preProcessed/gwas/results
mkdir -p chipatlas/results/hg19/insiicoChIP_preProcessed/lib
mkdir -p chipatlas/results/mm9/insiicoChIP_preProcessed/fantomPromoter/geneList
mkdir -p chipatlas/results/mm9/insiicoChIP_preProcessed/fantomPromoter/results
mkdir -p chipatlas/results/mm9/insiicoChIP_preProcessed/lib


##########################################################################################################################################################################
#                                                                         GWAS catalog
##########################################################################################################################################################################
# Gene body BED ファイルの作成
curl "http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/refFlat.txt.gz"| gunzip| cut -f3,5,6| sort -k1,1 -k2,2n| bedtools merge -i stdin > "$geneBody"

# GWAS の ダウンロード
    # 除去 %&()*+.:;
    # そのまま ',-
    # スペースに /
curl http://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/gwasCatalog.txt.gz| gunzip| cut -f2-| sort -t $'\t' -k10| awk -F '\t' '{
  if (!a[$10]++) i++
  trait = $10
  gsub(/Red vs\. non-red hair color/, "Red vs  non-red hair color", trait)
  gsub(/[%&\(\)\*+\.\:\;]/, "", trait)
  gsub(/\//, " ", trait)
  gsub(/ /, "_", trait)
  printf "%s\t%04d\t%s\n", $0, i, trait
}' > "$gwasCatalog" # $1-3 = BED,  $9 = title, $10 = trait, $23 = ID for trait, $24 = 記号文字を修正した trait

# 疾患特異的 BED ファイルの作成
width=500
cat "$gwasCatalog"| awk -F '\t' -v width=$width '{
  printf "%s\t%d\t%d\t%s\n", $1, $2-width, $2+width, $24
}'| bedtools intersect -v -a stdin -b "$geneBody"| sort -k1,1 -k2,2n| uniq| tee "$allGWAS"| awk -F '\t' -v dir="chipatlas/results/hg19/insiicoChIP_preProcessed/gwas/bed" -v gwasCatalog="$gwasCatalog" '
BEGIN {
  while ((getline < gwasCatalog) > 0) a[$24] = $23
} {
  bed = dir "/" a[$4] ".bed"
  print > bed
}'

# 疾患特異的 GWAS とその他の GWAS で in silico ChIP
for bed in `ls chipatlas/results/hg19/insiicoChIP_preProcessed/gwas/bed/*.bed`; do
  outFn=`echo $bed| sed 's/.bed$//g'| sed 's[/bed/[/results/[g'`
  bn=$(cat "$gwasCatalog"| awk -v id=`basename $outFn` -F '\t' '{if (id == $23) print $24}'| head -n1| tr '_' ' ')
  qsub -o /dev/null -e /dev/null bin/insilicoChIP -a $bed -b $allGWAS -Q 10 -A "$bn" -B "Other GWAS" -T "$bn vs Other GWAS" -v -o bed hg19 "$outFn"
done

while :; do
  qN=`qstat| awk '$3 == "insilicoCh"'| wc -l`
  if [ $qN -eq 0 ]; then
    rm chipatlas/results/hg19/insiicoChIP_preProcessed/gwas/results/*_Overlap.bb
    rm chipatlas/results/hg19/insiicoChIP_preProcessed/gwas/results/*_Overlap.bed
    break
  fi
done

# 疾患特異的 GWAS リストの作成
gwasCatalog="chipatlas/results/hg19/insiicoChIP_preProcessed/lib/gwasCatalog_original.bed"
awk -F '\t' -v gwasCatalog="$gwasCatalog" '
BEGIN {
  while ((getline < gwasCatalog) > 0) a[$23] = $10
} {
  if (FNR == 1) {
    for (i in a) {
      fn = "/" i ".tsv"
      if (FILENAME ~ fn) {
        trait = a[i]
        id = i
      }
    }
    gsub("%", "", trait)
    gwasQuery = trait
    htmlUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/hg19/insiicoChIP_preProcessed/gwas/results/" id ".html"
    tsvUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/hg19/insiicoChIP_preProcessed/gwas/results/" id ".tsv"
    zipUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/hg19/insiicoChIP_preProcessed/gwas/results/" id "_BED.zip"
    bedUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/hg19/insiicoChIP_preProcessed/gwas/bed/" id ".bed"
    wclbed = "cat chipatlas/results/hg19/insiicoChIP_preProcessed/gwas/bed/" id ".bed| wc -l"
    wclbed | getline num
    close(wclbed)
    gsub(" ", "%20", gwasQuery)
    
  
    printf "<tr>\n<td><a target=\"_blank\" style=\"text-decoration: none\" href=\"https://www.ebi.ac.uk/gwas/search?query="
    printf "%s", gwasQuery
    printf "\"><i class=\"fa fa-info-circle\" title=\"liTitle\"></i> </a>"
    printf trait
    printf "</td>\n"
    
    printf "<td align=\"center\"><a target=\"_blank\" style=\"text-decoration: none\" href=\""
    printf "%s", htmlUrl
    printf "\">HTML</a>, <a target=\"_blank\" style=\"text-decoration: none\" href=\""
    printf "%s", tsvUrl
    printf "\">TSV</a>, <a target=\"_blank\" style=\"text-decoration: none\" href=\""
    printf "%s", zipUrl
    printf "\">BED</a></td>\n"
    
    printf "<td align=\"right\"><a target=\"_blank\" style=\"text-decoration: none\" href=\""
    printf "%s", bedUrl
    printf "\">%d</a></td>\n", num
    
    printf "<td align=\"right\">%.1f</td>\n", $9
    printf "<td align=\"right\">%.1f</td>\n", $10
  }
}' chipatlas/results/hg19/insiicoChIP_preProcessed/gwas/results/*tsv| awk -v gwasList_template="chipatlas/sh/analTools/gwasList_template.html" '
BEGIN {
  while ((getline < gwasList_template) > 0) {
    if ($1 == "__tbody__") break
    print
  }
  close(gwasList_template)
} {
  print
} END {
  while ((getline < gwasList_template) > 0) {
    if (j > 0) print
    if ($1 == "__tbody__") j = 1
  }
}' > chipatlas/results/hg19/insiicoChIP_preProcessed/gwas/gwaslist.html

# 疾患特異的 GWAS 結果にリンクを設ける
for html in `ls chipatlas/results/hg19/insiicoChIP_preProcessed/gwas/results/*.html`; do
  id=`basename $html| sed 's/\.html//'`
  cat $html| sed 's[<p>Search for proteins significantly bound to your data\.</p>[['| awk -v id=$id '{
    if ($0 ~ "<caption><h2>") {
      zipUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/hg19/insiicoChIP_preProcessed/gwas/results/" id "_BED.zip"
      $0 = $0 "\n" "<caption><a target=\"_blank\" style=\"text-decoration: none\" href=\"" zipUrl "\">Download overlapped regions in BED format.</a><br><br><br></caption>"
    }
    print $0
  }' > $html"tmp"
  mv $html"tmp" $html
done

# GWAS と overlap する BED ファイルを 整形する
for dir in `ls chipatlas/results/hg19/insiicoChIP_preProcessed/gwas/results/| grep "_BED"`; do
  qsub -o /dev/null -e /dev/null -l short chipatlas/sh/analTools/preProcessed_insilico_BED.sh "chipatlas/results/hg19/insiicoChIP_preProcessed/gwas/results/$dir" gwas $width
done # chr12   115836521       115836522       CTCF_@SRX199886   rs1292011


##########################################################################################################################################################################
#                                                                         FANTOM Enhancer
##########################################################################################################################################################################

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
cd chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/bed
tar zxvf ~/facet_differentially_expressed_0.05.tgz
cd
rm facet_differentially_expressed_0.05.tgz
mv chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/bed/0_05/* chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/bed/
rm -r chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/bed/0_05


ls chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/bed/*bed| awk -F '\t' -v id2name="$id2name" '
BEGIN {
  while ((getline < id2name) > 0) {     # Fantom enhancer の facet 名を正式名称に変える
    gsub(" ", "_", $2)
    x[$1] = $2          # x[UBERON:0002106] = spleen
  }
} {
  split($1, f, "/")     # f[6] = UBERON:0002106_spleen_differentially_expressed_enhancers.bed
  split(f[7], i, "_")   # i[1] = UBERON:0002106
  print "mv " $1 " chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/bed/" i[1] "_" x[i[1]] "_differentially_expressed_enhancers.bed"
}'| sh
#####################################################################################
## 注意: Fantom enhancer の facet 名は、正式でないものがある
#####################################################################################
# ID              正式名称                         Fantom enhancer
# CL:0002327      mammary gland epithelial cell   mammary epithelial cell
# CL:0000188      cell of skeletal muscle         skeletal muscle cell
# CL:0000746      cardiac muscle cell             cardiac myocyte
# UBERON:0001044  saliva-secreting gland          salivary gland


# facet_differentially_expressed_enhancers をまとめる
bedB="chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/differentially_expressed_enhancers_uniq.bed"
for bed in `ls chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/bed/*.bed`; do
  outfn="chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/bed/"`basename "$bed"| sed 's/_/@/'| cut -d '@' -f1`".bed"
  description=`basename "$bed"| sed 's/_differentially_expressed_enhancers\.bed//'`
  cut -f1-3 $bed| sort -k1,1 -k2,2n| uniq| awk -v description="$description" '{print $0 "\t" description}'| tee $outfn
  rm "$bed"
done| cut -f1-3| sort -k1,1 -k2,2n| uniq > "$bedB"  # chr1  1005293  1005547  重複する領域を削除 (重要!!!!)

# in silico ChIP の実行
for bedA in `ls chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/bed/*.bed`; do
  titleA=`head -n1 "$bedA"| cut -f4| sed 's/_/@/'| cut -d '@' -f2| tr '_' ' '| sed 's/\(.\)\(.*\)/\U\1\L\2/g'`
  outFn=`echo "$bedA"| sed 's[/bed/[/results/['| sed 's/\.bed$//'`
  cut -f1-3 "$bedA" > "$bedA".tmp
  qsub -o /dev/null -e /dev/null bin/insilicoChIP -a "$bedA".tmp -b "$bedB" -Q 10 -A "$titleA" -B "Other enhancers" -v -o bed hg19 "$outFn"
done

while :; do
  qN=`qstat| awk '$3 == "insilicoCh"'| wc -l`
  if [ $qN -eq 0 ]; then
    rm chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/bed/*.bed.tmp
    rm chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/results/*_Overlap.bb
    rm chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/results/*_Overlap.bed
    break
  fi
done

# 組織特異的 Enhancer リストの作成
awk -F '\t' -v id2name="$id2name" '
BEGIN {
  while ((getline < id2name) > 0) {
    c = substr($2, 1, 1)
    sub(c, toupper(c), $2)
    a[$1] = $2      #a[CL:0000050] = Megakaryocyte-erythroid progenitor cell
  }
} {
  if (FNR == 1) {
    for (i in a) {
      fn = "/" i ".tsv"
      if (FILENAME ~ fn) {
        trait = a[i]
        id = i
      }
    }
    htmlUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/hg19/insiicoChIP_preProcessed/fantomEnhancer/results/" id ".html"
    tsvUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/hg19/insiicoChIP_preProcessed/fantomEnhancer/results/" id ".tsv"
    bedUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/hg19/insiicoChIP_preProcessed/fantomEnhancer/bed/" id ".bed"
    zipUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/hg19/insiicoChIP_preProcessed/fantomEnhancer/results/" id "_BED.zip"
    wclbed = "cat chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/bed/" id ".bed| wc -l"
    wclbed | getline num
    close(wclbed)
    
    printf "<tr>\n<td><a target=\"_blank\" style=\"text-decoration: none\" href=\"http://fantom.gsc.riken.jp/5/sstar/"
    printf "%s", id
    printf "\"><i class=\"fa fa-info-circle\" title=\"liTitle\"></i> </a>"
    printf id "</td>\n<td>" trait
    printf "</td>\n"
    
    printf "<td align=\"center\"><a target=\"_blank\" style=\"text-decoration: none\" href=\""
    printf "%s", htmlUrl
    printf "\">HTML</a>, <a target=\"_blank\" style=\"text-decoration: none\" href=\""
    printf "%s", tsvUrl
    printf "\">TSV</a>, <a target=\"_blank\" style=\"text-decoration: none\" href=\""
    printf "%s", zipUrl
    printf "\">BED</a></td>\n"
    
    printf "<td align=\"right\"><a target=\"_blank\" style=\"text-decoration: none\" href=\""
    printf "%s", bedUrl
    printf "\">%d</a></td>\n", num
    
    printf "<td align=\"right\">%.1f</td>\n", $9
    printf "<td align=\"right\">%.1f</td>\n", $10
  }
}' chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/results/*tsv| awk -v template="chipatlas/sh/analTools/fantomEnhancerList_template.html" '
BEGIN {
  while ((getline < template) > 0) {
    if ($1 == "__tbody__") break
    print
  }
  close(template)
} {
  print
} END {
  while ((getline < template) > 0) {
    if (j > 0) print
    if ($1 == "__tbody__") j = 1
  }
}' > chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/fantomEnhancerlist.html

# 組織特異的 Enhancer の結果にリンクを設ける
for html in `ls chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/results/*.html`; do
  id=`basename $html| sed 's/\.html//'`
  cat $html| sed 's[<p>Search for proteins significantly bound to your data\.</p>[['| awk -v id=$id '{
    if ($0 ~ "<caption><h2>") {
      zipUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/hg19/insiicoChIP_preProcessed/fantomEnhancer/results/" id "_BED.zip"
      $0 = $0 "\n" "<caption><a target=\"_blank\" style=\"text-decoration: none\" href=\"" zipUrl "\">Download overlapped regions in BED format.</a><br><br><br></caption>"
    }
    print $0
  }' > $html"tmp"
  mv $html"tmp" $html
done

# 組織特異的 Enhancer と overlap する BED ファイルを 整形する
for dir in `ls chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/results/| grep "_BED"`; do
  qsub -o /dev/null -e /dev/null -l short chipatlas/sh/analTools/preProcessed_insilico_BED.sh "chipatlas/results/hg19/insiicoChIP_preProcessed/fantomEnhancer/results/$dir" enhancer
done # chr12   115836521       115836522       CTCF_@SRX199886   rs1292011



##########################################################################################################################################################################
#                                                                         FANTOM Promoter
##########################################################################################################################################################################

for genome in hg19 mm9; do
  p2g="chipatlas/results/$genome/insiicoChIP_preProcessed/lib/promoter2geneSymbols.bed"
  case $genome in
    "hg19" ) org=human;;
    "mm9" )  org=mouse;;
  esac
  # promoter と gene symbol のダウンロードと整形
  curl "http://fantom.gsc.riken.jp/5/datafiles/phase1.3/extra/TSS_classifier/TSS_"$org".bed.gz"| gunzip| tr '@,' '\t\t'| awk -F '\t' -v OFS='\t' -v fn="$fn" '{
    if ($4 != "p") print $1, $2, $3, $5, $4, $8
  }' > "$p2g"  # chr10   101621605       101621610       Mgat4c  p18     +

  # 細胞特異的プロモータリストのダウンロードと整形
  urlHead="http://fantom.gsc.riken.jp/5/datafiles/phase1.3/extra/Sample_ontology_enrichment_of_CAGE_peaks/"
  curl "$urlHead""$genome""exp_cell_types_general_term_excluded.txt.gz"| gunzip > chipatlas/results/$genome/insiicoChIP_preProcessed/lib/specificPromoters.CL.txt
  curl "$urlHead""$genome""exp_disease_general_term_excluded.txt.gz"| gunzip > chipatlas/results/$genome/insiicoChIP_preProcessed/lib/specificPromoters.DOID.txt
  curl "$urlHead""$genome""exp_uberon_general_term_excluded.txt.gz"| gunzip > chipatlas/results/$genome/insiicoChIP_preProcessed/lib/specificPromoters.UBERON.txt
  # chr10:100993894..100993906,-    CL:0000097[p.value=7.36e-45,n=5];CL:0002028[p.value=7.36e-45,n=5];CL:0000163[p.value=2.47e-25,n=9];CL:0000151[p.value=7.52e-07,n=36]

  # 細胞特異的 gene list の作成
  geneListDir="chipatlas/results/"$genome"/insiicoChIP_preProcessed/fantomPromoter/geneList"
  for class in CL DOID UBERON; do
    cat "chipatlas/results/$genome/insiicoChIP_preProcessed/lib/specificPromoters.$class.txt"| tr ';' '\t'| awk -F '\t' -v OFS='\t' -v p2g="$p2g" '
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
done


# in silico ChIP の実行
up=10000
down=10000
for genome in hg19 mm9; do
  for geneList in `ls "chipatlas/results/"$genome"/insiicoChIP_preProcessed/fantomPromoter/geneList/"*.geneList.txt`; do
    id=`basename $geneList| cut -d '.' -f1`
    titleA=`cat $id2name| awk -F '\t' -v id="$id" '$1 == id {printf $2}'| sed 's/\(.\)\(.*\)/\U\1\L\2/g'`
    titleB="Other RefSeq genes"
    outfn="chipatlas/results/$genome/insiicoChIP_preProcessed/fantomPromoter/results/"$id
    qsub -o /dev/null -e /dev/null bin/insilicoChIP -a "$geneList" -A "$titleA" -B "$titleB" -T "$titleA vs $titleB" -o -u $up -d $down gene "$genome" "$outfn"
  done
done




while :; do
  qN=`qstat| awk '$3 == "insilicoCh"'| wc -l`
  if [ $qN -eq 0 ]; then
    rm chipatlas/results/*/insiicoChIP_preProcessed/fantomPromoter/results/*_Overlap.bb
    rm chipatlas/results/*/insiicoChIP_preProcessed/fantomPromoter/results/*_Overlap.bed
    break
  fi
done

# 組織特異的 gene リストの作成
for genome in hg19 mm9; do
  awk -F '\t' -v id2name="$id2name" -v genome=$genome '
  BEGIN {
    while ((getline < id2name) > 0) {
      c = substr($2, 1, 1)
      sub(c, toupper(c), $2)
      a[$1] = $2      #a[CL:0000050] = Megakaryocyte-erythroid progenitor cell
    }
  } {
    if (FNR == 1) {
      for (i in a) {
        fn = "/" i ".tsv"
        if (FILENAME ~ fn) {
          trait = a[i]
          id = i
        }
      }
      htmlUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/" genome "/insiicoChIP_preProcessed/fantomPromoter/results/" id ".html"
      tsvUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/" genome "/insiicoChIP_preProcessed/fantomPromoter/results/" id ".tsv"
      bedUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/" genome "/insiicoChIP_preProcessed/fantomPromoter/geneList/" id ".geneList.txt"
      zipUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/" genome "/insiicoChIP_preProcessed/fantomPromoter/results/" id "_BED.zip"
      wclbed = "cat chipatlas/results/" genome "/insiicoChIP_preProcessed/fantomPromoter/geneList/" id ".geneList.txt| wc -l"
      wclbed | getline num
      close(wclbed)
      
      printf "<tr>\n<td><a target=\"_blank\" style=\"text-decoration: none\" href=\"http://fantom.gsc.riken.jp/5/sstar/"
      printf "%s", id
      printf "\"><i class=\"fa fa-info-circle\" title=\"liTitle\"></i> </a>"
      printf id "</td>\n<td>" trait
      printf "</td>\n"
      
      printf "<td align=\"center\"><a target=\"_blank\" style=\"text-decoration: none\" href=\""
      printf "%s", htmlUrl
      printf "\">HTML</a>, <a target=\"_blank\" style=\"text-decoration: none\" href=\""
      printf "%s", tsvUrl
      printf "\">TSV</a>, <a target=\"_blank\" style=\"text-decoration: none\" href=\""
      printf "%s", zipUrl
      printf "\">BED</a></td>\n"
      
      printf "<td align=\"right\"><a target=\"_blank\" style=\"text-decoration: none\" href=\""
      printf "%s", bedUrl
      printf "\">%d</a></td>\n", num
      
      printf "<td align=\"right\">%.1f</td>\n", $9
      printf "<td align=\"right\">%.1f</td>\n", $10
    }
  }' chipatlas/results/$genome/insiicoChIP_preProcessed/fantomPromoter/results/*tsv| awk -v template="chipatlas/sh/analTools/fantomPromoterList_template.html" -v genome=$genome '
  BEGIN {
    while ((getline < template) > 0) {
      if ($1 == "__tbody__") break
      print
    }
    close(template)
  } {
    print
  } END {
    while ((getline < template) > 0) {
      sub("__GENOME__", genome, $0)
      if (j > 0) print
      if ($1 == "__tbody__") j = 1
    }
  }' > chipatlas/results/$genome/insiicoChIP_preProcessed/fantomPromoter/fantomPromoterlist.html
done

# 組織特異的 Enhancer の結果にリンクを設ける
for genome in hg19 mm9; do
  for html in `ls chipatlas/results/$genome/insiicoChIP_preProcessed/fantomPromoter/results/*.html`; do
    id=`basename $html| sed 's/\.html//'`
    cat $html| sed 's[<p>Search for proteins significantly bound to your data\.</p>[['| awk -v id=$id -v genome=$genome '{
      if ($0 ~ "<caption><h2>") {
        zipUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/" genome "/insiicoChIP_preProcessed/fantomPromoter/results/" id "_BED.zip"
        $0 = $0 "\n" "<caption><a target=\"_blank\" style=\"text-decoration: none\" href=\"" zipUrl "\">Download overlapped regions in BED format.</a><br><br><br></caption>"
      }
      print $0
    }' > $html"tmp"
    mv $html"tmp" $html
  done
done


# Gene と overlap する BED ファイルを 整形する
for genome in hg19 mm9; do
  for dir in `ls chipatlas/results/$genome/insiicoChIP_preProcessed/fantomPromoter/results/| grep "_BED"`; do
    qsub -o /dev/null -e /dev/null -l short chipatlas/sh/analTools/preProcessed_insilico_BED.sh "chipatlas/results/"$genome"/insiicoChIP_preProcessed/fantomPromoter/results/$dir" promoter $up $down
  done
done

    
    
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
    }' chipatlas/results/$genome/insiicoChIP_preProcessed/fantomPromoter/results/"$dir/"*.bed
    for bed in `ls chipatlas/results/$genome/insiicoChIP_preProcessed/fantomPromoter/results/"$dir/"*.bed`; do
      sort -k1,1 -k2,2n $bed"tmp"| uniq > $bed
      rm $bed"tmp"
    done
  done # chr21  45138977  45138978  SP1_@SRX100550  PDXK  NM_003681   +
done

promoter up down

# Gene と overlap する BED ファイルを 整形する
for dir in `ls chipatlas/results/hg19/insiicoChIP_preProcessed/gwas/results/| grep "_BED"`; do
  qsub -o /dev/null -e /dev/null -l short chipatlas/sh/analTools/preProcessed_insilico_BED.sh "chipatlas/results/hg19/insiicoChIP_preProcessed/gwas/results/$dir" gwas
done # chr12   115836521       115836522       CTCF_@SRX199886   rs1292011
