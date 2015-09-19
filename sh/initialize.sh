#!/bin/sh
#$ -S /bin/sh

# このシェルは以下のコマンドで投入
# sh chipome_ver3/sh/initialize.sh

projectDir=`echo $0| sed 's[/sh/initialize.sh[['`
QSUB="sh $projectDir/sh/QSUB.sh"

GENOME=`cat $projectDir/sh/preferences.txt |awk -F '\t' '{
  if ($1 == "Genome") {
    split($2, all, " ")
    for (key in all) {
      split (all[key], arr, "=")
      printf "%s ", arr[1]
    }
  }
}'`

QVAL=`cat $projectDir/sh/preferences.txt |awk -F '\t' '{if ($1 == "qVal") print $2}'`

mkdir $projectDir/bin
mkdir $projectDir/results
mkdir $projectDir/classification
mkdir $projectDir/lib
mkdir $projectDir/lib/metadata
mkdir $projectDir/lib/bowtie_index
mkdir $projectDir/lib/genome_size
mkdir $projectDir/lib/whole_genome_fa
mkdir $projectDir/lib/assembled_list

sh $projectDir/sh/toolPrep.sh $projectDir # CLI ツールのインストール

for Genome in `echo $GENOME`; do
  $QSUB -o genomeSettings.$Genome.log -e genomeSettings.$Genome.log -pe def_slot 1 $projectDir/sh/genomeSettings.sh $projectDir $Genome # genome Library の作成
  mkdir $projectDir/results/$Genome
  mkdir $projectDir/results/$Genome/BigWig
  mkdir $projectDir/results/$Genome/log
  mkdir $projectDir/results/$Genome/summary
  mkdir $projectDir/results/$Genome/metadata
  mkdir $projectDir/results/$Genome/public
  for qval in `echo $QVAL`; do
    mkdir $projectDir/results/$Genome/Bed$qval
    mkdir $projectDir/results/$Genome/Bed$qval/Bed
    mkdir $projectDir/results/$Genome/Bed$qval/BigBed
  done
done

sh $projectDir/sh/metaPrep.sh $projectDir # メタデータの作成

while :; do
  qstatGenome=`qstat| awk '{if ($3 == "genomeSett") print}'| wc -l`
  if [ $qstatGenome -eq 0 ]; then
    break
  fi
done

qsub $projectDir/sh/Controller.sh "$GENOME" $projectDir "$QVAL" $projectDir/lib/metadata/*.metadata.tab
# $1 ゲノム (例 "hg19 mm9 ce10 dm3 sacCer3")
# $2 projectDir (例 chipome_ver3)
# $3 Qval (例 "05 10 20")
# $4 メタデータ (例 NCBI_SRA_Metadata_Full_20150101.metadata.tab)






