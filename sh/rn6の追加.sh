===========================================================================
ChIP-Atlas に Rat rn6 を加える 2017.11.03
===========================================================================
== libPrepForAnal.sh への加筆 ==
# protein-coding gene の列挙
    rn6)
      echo -e "$Genome\tEnsembl_RGD" >> keyForStringFiltering
      curl ftp://ftp.rgd.mcw.edu/pub/data_release/GENES_RAT.txt| awk -F '\t' '{
        if ($37 == "protein-coding") print $2
      }'
    ;;

== geneNameToUniqueTSS.sh への加筆 ==
# rn6 の unique TSS を追加
    "rn6" ) # ラットは RefSeq genes がないので、RGD の ID で代用
        curl ftp://ftp.rgd.mcw.edu/pub/data_release/GENES_RAT.txt| awk -F '\t' -v OFS='\t' '{
          if ($1 + 0 > 0 && $37 == "protein-coding" && length($44) > 0) {
            split($44, a, ";")
            split($45, b, ";")
            split($46, c, ";")
            split($47, d, ";")
            sub("MT", "M", a[1])
            print "chr" a[1], b[1], c[1], $2, d[1], "RGD_" $1
          }
        }'| sort -k1,1 -k2,2n > $projectDir/lib/TSS/uniqueTSS.$Genome.bed
      ;;

== preferences に rat rn6 を追加 == 
cat chipatlas/sh/preferences.txt| awktt '{
  if ($1 == "Genome") $2 = "hg19=Homo_sapiens mm9=Mus_musculus rn6=Rattus_norvegicus ce10=Caenorhabditis_elegans dm3=Drosophila_melanogaster sacCer3=Saccharomyces_cerevisiae"
  print
}' > tmp/chipatlas_preferences.tmp
mv tmp/chipatlas_preferences.tmp chipatlas/sh/preferences.txt


== Bowtie index などの作成 == 
cat << 'DDD' | qsub -pe def_slot 4- -l debug
  #!/bin/sh
  #$ -S /bin/sh
  Genome=rn6
  
  # 2bit の download
  bin/ntcurl -o "-y60 -Y1 -C - -o chipatlas/lib/whole_genome_fa/$Genome.2bit" http://hgdownload.cse.ucsc.edu/goldenPath/$Genome/bigZips/$Genome.2bit
  # Fasta の作成
  chipatlas/bin/twoBitToFa chipatlas/lib/whole_genome_fa/$Genome.2bit chipatlas/lib/whole_genome_fa/$Genome.fa
  rm chipatlas/lib/whole_genome_fa/$Genome.2bit
  # bowtie2 index
  chipatlas/bin/bowtie2-2.2.2/bowtie2-build chipatlas/lib/whole_genome_fa/$Genome.fa chipatlas/lib/bowtie_index/$Genome
  # genome size
  ntcurl ftp://hgdownload.cse.ucsc.edu/goldenPath/$Genome/database/chromInfo.txt.gz| gunzip| cut -f1,2 | sort -k2nr > chipatlas/lib/genome_size/$Genome.chrom.sizes
DDD


== ディレクトリの作成  (スパコン) == 
QVAL=`cat chipatlas/sh/preferences.txt |awk -F '\t' '{if ($1 == "qVal") print $2}'`
Genome=rn6
mkdir chipatlas/results/$Genome
mkdir chipatlas/results/$Genome/BigWig
mkdir chipatlas/results/$Genome/log
mkdir chipatlas/results/$Genome/summary
mkdir chipatlas/results/$Genome/metadata
mkdir chipatlas/results/$Genome/public
for qval in `echo $QVAL`; do
  mkdir chipatlas/results/$Genome/Bed$qval
  mkdir chipatlas/results/$Genome/Bed$qval/Bed
  mkdir chipatlas/results/$Genome/Bed$qval/BigBed
done

== ディレクトリの作成  (NBDC) == 
mkdir -p /mnt/kyushu/data/rn6/allPeaks_light
mkdir -p /mnt/kyushu/data/rn6/assembled
mkdir -p /mnt/kyushu/data/rn6/colo
mkdir -p /mnt/kyushu/data/rn6/eachData
mkdir -p /mnt/kyushu/data/rn6/log
mkdir -p /mnt/kyushu/data/rn6/metadata
mkdir -p /mnt/kyushu/data/rn6/summary
mkdir -p /mnt/kyushu/data/rn6/target

== ディレクトリの作成  (w3oki) == 
mkdir w3oki/chipatlas/results/rn6


== sraTailor.sh への加筆 == 
  rn6) macsg=2.15e9;;  # total genome size (= 2.87e9) の 75%

== sh/curationTool/prepForGeneSynonym.sh への加筆 == 
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


== sh/curationTool/curator.html への加筆 (rn6 の追加と、mesh の更新) == 
      <option value="rn6">rn6</option>
        [dbname[2], 2, 2,        2, 8, 3, 8, 8     , "mesh2017.tab"],

== MeSH を更新するため、下記の 「MeSH の準備」を実行 == 
/Users/Oki/Desktop/沖　真弥/実験/chipAtlas/Curation/Cell_Nomenclature/キュレーションファイルの作り方.sh

== ATCC の rat 細胞を追加するため、下記の 「ATCC の整理」を実行 == 
/Users/Oki/Desktop/沖　真弥/実験/chipAtlas/Curation/Cell_Nomenclature/キュレーションファイルの作り方.sh

== 初回のみ、curator の cell type と antiggen を mm9 と同じにするためにコピー == 
cp /mnt/kyushu/data/util/curationTool/classification/ct_Statistics-mm9-tab.tsv /mnt/kyushu/data/util/curationTool/classification/ct_Statistics-rn6-tab.tsv
cp /mnt/kyushu/data/util/curationTool/classification/ag_Statistics-mm9-tab.tsv /mnt/kyushu/data/util/curationTool/classification/ag_Statistics-rn6-tab.tsv

== データ集計用のスクリプトを修正 == 
  dataNumbers.sh, dataNumbers.R に "rn6" や "R. norvegicus" を追加

== NBDC への転送スクリプトへの加筆 == 
/usr/local/bin/transferDDBJtoNBDC に ce10 を rn6 に置換して配置。




== in silico ChIP wabi のための準備 == 
# w3oki/chipatlas/lib/bowtie_index/ 配下に rn6 の bowtie1 index を準備
w3oki
bowtie-build chipatlas/lib/whole_genome_fa/rn6.fa w3oki/chipatlas/lib/bowtie_index/rn6

# rn6.chrom.sizes を w3oki 配下にコピー
cp chipatlas/lib/genome_size/rn6.chrom.sizes w3oki/chipatlas/lib/genome_size/rn6.chrom.sizes




==============================================================
これより本番
==============================================================
== アップデートの開始 ==
sh chipatlas/sh/upDate.sh  # <<=== コマンド (DDBJ) すぐに qsub されるので、どの mac でも可能
  
== Controller.sh が開始した時、rn6 の metadataForRun.txt を新規に書き換える ==
cat chipatlas/lib/metadata/NCBI_SRA_Metadata_Full_20171027.metadata.tab| awk -v ORG="Rattus norvegicus" -F '\t' '{
  if ($4  == "ChIP-Seq" || $4  == "DNase-Hypersensitivity")\
  if ($5  == "GENOMIC")\
  if ($6  == "ChIP" || $6  == "DNase")\
  if ($11 ~  "Illumina")\
  if ($17 ~  ORG)\
    print
}' > chipatlas/results/rn6/metadataForRun.txt

== あとは通常通り。colo が終わるまで待つ ==

== in silico ChIP wabi のためのサンプルデータの作成。下記に rn6 を追加し、スパコンにて実行 ==
/Users/Oki/Desktop/沖　真弥/実験/chipAtlas/スクリプト/chipatlas_git/sh/analTools/samplesForInSilicoChIP.sh
# NBDC にログインし、スパコンから NBDC に転送。
rsync -auzv -e ssh okishinya@gw2.ddbj.nig.ac.jp:sample4insilicoChIP/ /mnt/kyushu/data/sample/sample4insilicoChIP/
# 転送が終わったら、スパコンで sample4insilicoChIP フォルダを消去して良い。
rm -r sample4insilicoChIP


== in silico ChIP wabi の Web アプリに必要なパラメータをおおたさんに伝える ==
awktt '{x[FILENAME] += $2} END {for (i in x) print i, x[i]}' chipatlas/lib/genome_size/*.chrom.sizes
wc -l chipatlas/lib/TSS/uniqueTSS.*
を実行し、下記のパラメータを伝える
var genomesize = {
 ce10: 100286070,
 dm3: 168736537,
 hg19: 3137161264,
 mm9: 2725765481,
 rn6: 2870182909,
 sacCer3: 12157105
};
var numGenes = {
 ce10: 17162,
 dm3: 12575,
 hg19: 18550,
 mm9: 19876,
 rn6: 23425,
 sacCer3: 5809
};






