===========================================================================
ChIP-Atlas に hg38 などを加える 2019.07.09
===========================================================================
== 追加すべきゲノムアセンブリ ==
ce10  dm3  hg19  mm9  rn6  sacCer3
ce11  dm6  hg38  mm10 -    -

== preferences.txt への加筆 (ゲノムアセンブリ名) ==
Genome	hg19,hg38=Homo_sapiens mm9,mm10=Mus_musculus rn6=Rattus_norvegicus ce10,ce11=Caenorhabditis_elegans dm3,dm6=Drosophila_melanogaster sacCer3=Saccharomyces_cerevisiae	ゲノムアセンブリと学名 (intialize.sh, Controller.sh)

== upDate.sh への加筆 (UCSC からのダウンロード) ==
    "hg19" | "hg38" | "mm9" | "mm10" )
    "ce10" | "ce11" )
    "dm3" | "dm6" )

== geneNameToUniqueTSS.sh への加筆 ==
    "hg19" | "hg38" | "mm9" | "mm10" )
    "ce10" | "ce11" )
    "dm3" | "dm6" )

== libPrepForAnal.sh への加筆 ==
  # protein-coding 遺伝子リストの作成
    "hg19" | "hg38" | "mm9" | "mm10" )
    "ce10" | "ce11" )
    "dm3" | "dm6" )
    # 生物種と ID の対応付け
      split(a[1], t, ",")
      g[t[1]] = a[2]      # g["hg19"] = "Homo sapiens"
      org[a[2]] = t[1]    # org["Homo sapiens"] = "hg19"
  # 最後に新規ゲノムの STRING ファイルをコピー
function copy_action() {
  cat protein.actions.v11.0.$1.txt > protein.actions.v11.0.$2.txt
}
copy_action hg19 hg38
copy_action mm9 mm10
copy_action ce10 ce11
copy_action dm3 dm6

== Controller.sh への加筆 ==
  # Organism Name の取得
        if (arr[1] ~ G) {

== Bowtie index などの作成 ==
# ce11, dm6 の 2bit の download, Fasta の作成, bowtie2 index
for Genome in ce11 dm6; do
  curl http://hgdownload.cse.ucsc.edu/goldenPath/$Genome/bigZips/$Genome.2bit > chipatlas/lib/whole_genome_fa/$Genome.2bit
  chipatlas/bin/twoBitToFa chipatlas/lib/whole_genome_fa/$Genome.2bit chipatlas/lib/whole_genome_fa/$Genome.fa
  rm chipatlas/lib/whole_genome_fa/$Genome.2bit
  chipatlas/bin/bowtie2-2.2.2/bowtie2-build chipatlas/lib/whole_genome_fa/$Genome.fa chipatlas/lib/bowtie_index/$Genome
done

# hg38 の bowtie index
wget ftp://ftp.ncbi.nlm.nih.gov/genomes/archive/old_genbank/Eukaryotes/vertebrates_mammals/Homo_sapiens/GRCh38/seqs_for_alignment_pipelines/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bowtie_index.tar.gz
tar -zxvf GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bowtie_index.tar.gz
rm GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bowtie_index.tar.gz
for fn in `ls GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bowtie_index*2`; do
  outfn="hg38."`echo $fn| cut -d '.' -f5-`
  mv $fn chipatlas/lib/bowtie_index/$outfn
done

# mm10 の bowtie index
wget ftp://ftp.ccb.jhu.edu/pub/data/bowtie2_indexes/mm10.zip
unzip mm10.zip
rm mm10.zip
mv mm10*bt2 chipatlas/lib/bowtie_index/
rm make_mm10.sh

# Genome size
for Genome in hg38 mm10 ce11 dm6; do
  curl ftp://hgdownload.cse.ucsc.edu/goldenPath/$Genome/database/chromInfo.txt.gz| gunzip| cut -f1,2 | sort -k2nr > chipatlas/lib/genome_size/$Genome.chrom.sizes
done

== in silico ChIP wabi のための準備 == 
# bowtie1 index の作成
for Genome in ce11 dm6; do
  singularity exec /usr/local/biotools/b/bowtie:1.1.2--py35_1 bowtie-build chipatlas/lib/whole_genome_fa/$Genome.fa $Genome
done

wget ftp://ftp.ccb.jhu.edu/pub/data/bowtie_indexes/GRCh38_no_alt.zip
unzip GRCh38_no_alt.zip
rm GRCh38_no_alt.zip
for fn in `ls GCA_000001405.15_GRCh38_no_alt_analysis_set*ebwt`; do
  outfn="hg38."`echo $fn| cut -d '.' -f3-`
  mv $fn $outfn
done

w3oki
cp *ebwt /lustre7/home/w3oki/chipatlas/lib/bowtie_index/
cp extrinSeq/lib/bowtie_index/mm10.*ebwt /lustre7/home/w3oki/chipatlas/lib/bowtie_index/

# chrom.sizes を w3oki 配下にコピー
for Genome in hg38 mm10 ce11 dm6; do
  cp chipatlas/lib/genome_size/$Genome.chrom.sizes /lustre7/home/w3oki/chipatlas/lib/genome_size/$Genome.chrom.sizes
done
rm *ebwt









############ 未着手
== ディレクトリの作成  (スパコン) == # 一番上位に
for Genome in ce11 dm6 hg38 mm10; do
  mkdir chipatlas/results/$Genome
  mkdir chipatlas/results/$Genome/BigWig
  mkdir chipatlas/results/$Genome/log
  mkdir chipatlas/results/$Genome/summary
  mkdir chipatlas/results/$Genome/metadata
  mkdir chipatlas/results/$Genome/public
  for qval in `cat chipatlas/sh/preferences.txt |awk -F '\t' '{if ($1 == "qVal") print $2}'`; do
    mkdir chipatlas/results/$Genome/Bed$qval
    mkdir chipatlas/results/$Genome/Bed$qval/Bed
    mkdir chipatlas/results/$Genome/Bed$qval/BigBed
  done
done

== ディレクトリの作成  (NBDC) == # 一番上位に
for Genome in ce11 dm6 hg38 mm10; do
  mkdir -p /mnt/kyushu/data/$Genome/allPeaks_light
  mkdir -p /mnt/kyushu/data/$Genome/assembled
  mkdir -p /mnt/kyushu/data/$Genome/colo
  mkdir -p /mnt/kyushu/data/$Genome/eachData
  mkdir -p /mnt/kyushu/data/$Genome/log
  mkdir -p /mnt/kyushu/data/$Genome/metadata
  mkdir -p /mnt/kyushu/data/$Genome/summary
  mkdir -p /mnt/kyushu/data/$Genome/target
done

== ディレクトリの作成  (w3oki) == # 一番上位に
for Genome in ce11 dm6 hg38 mm10; do
  mkdir w3oki/chipatlas/results/$Genome
done






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


== MeSH を更新するため、下記の 「MeSH の準備」を実行 == 
/Users/Oki/Desktop/沖　真弥/実験/chipAtlas/Curation/Cell_Nomenclature/キュレーションファイルの作り方.sh

== ATCC の rat 細胞を追加するため、下記の 「ATCC の整理」を実行 == 
/Users/Oki/Desktop/沖　真弥/実験/chipAtlas/Curation/Cell_Nomenclature/キュレーションファイルの作り方.sh

== データ集計用のスクリプトを修正 == 
  dataNumbers.sh, dataNumbers.R に "rn6" や "R. norvegicus" を追加

== NBDC への転送スクリプトへの加筆 == 
/usr/local/bin/transferDDBJtoNBDC に ce10 を rn6 に置換して配置。






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






