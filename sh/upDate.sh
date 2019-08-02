#!/bin/sh
#$ -S /bin/sh

# このシェルは以下のコマンドで投入
# sh chipatlas/sh/upDate.sh

if [ "$1" = "" ]; then
  projectDir=`echo $0| sed 's[/sh/upDate.sh[['`
  ucscURL="http://hgdownload.cse.ucsc.edu/goldenPath"
  echo "UCSC よりライブラリファイルをダウンロードしています。"
  for Genome in `ls $projectDir/results`; do
    if [ $Genome != "sacCer3" ]; then
      curl $ucscURL/$Genome/database/refFlat.txt.gz
    else # sacCer3 は refFlat がないので、xenoRefFlat を使い、geneList と一致するものだけを抽出
      curl $ucscURL/$Genome/database/xenoRefFlat.txt.gz
    fi > $projectDir/lib/ucsc_tmp/$Genome.refFlat.txt.gz
    
    case $Genome in
    "hg19" | "hg38" | "mm9" | "mm10" )
      curl $ucscURL/$Genome/database/knownCanonical.txt.gz > $projectDir/lib/ucsc_tmp/$Genome.knownCanonical.txt.gz
      curl $ucscURL/$Genome/database/knownToRefSeq.txt.gz > $projectDir/lib/ucsc_tmp/$Genome.knownToRefSeq.txt.gz
      ;;
    "ce10" | "ce11" )
      curl $ucscURL/ce6/database/sangerCanonical.txt.gz > $projectDir/lib/ucsc_tmp/$Genome.sangerCanonical.txt.gz
      curl $ucscURL/ce6/database/sangerToRefSeq.txt.gz > $projectDir/lib/ucsc_tmp/$Genome.sangerToRefSeq.txt.gz
      ;;
    "dm3" | "dm6" )
      curl $ucscURL/dm3/database/flyBaseCanonical.txt.gz > $projectDir/lib/ucsc_tmp/$Genome.flyBaseCanonical.txt.gz
      curl $ucscURL/dm3/database/flyBaseToRefSeq.txt.gz> $projectDir/lib/ucsc_tmp/$Genome.flyBaseToRefSeq.txt.gz
      ;;
    "sacCer3" ) # 酵母は RefSeq genes がない
      curl $ucscURL/sacCer3/database/sgdCanonical.txt.gz > $projectDir/lib/ucsc_tmp/$Genome.sgdCanonical.txt.gz
      curl $ucscURL/sacCer3/database/sgdToName.txt.gz > $projectDir/lib/ucsc_tmp/$Genome.sgdToName.txt.gz
      curl $ucscURL/sacCer3/database/sgdGene.txt.gz > $projectDir/lib/ucsc_tmp/$Genome.sgdGene.txt.gz
      ;;
    esac
  done
  curl $ucscURL/hg19/database/gwasCatalog.txt.gz > $projectDir/lib/ucsc_tmp/gwasCatalog.txt.gz
  ql=`sh $projectDir/sh/QSUB.sh mem`
  qsub $ql -pe def_slot 4- $projectDir/sh/upDate.sh $projectDir
  exit
fi

####################################################################################################################################
#                                                             以下、qsub モード
####################################################################################################################################


projectDir=$1

newMeta=$(basename `ls $projectDir/lib/metadata/NCBI_SRA_Metadata_Full_2*.metadata.tab| sort| tail -n1`| cut -d '.' -f1) # 所持している最新版

# 最新の MetadataFull の名前を取得
MetadataFull=`lftp ftp.ncbi.nlm.nih.gov << EOS | grep NCBI_SRA_Metadata_Full_2| awk '{print $9}'| sort| tail -n1| cut -d '.' -f1
user anonymous \n
cd sra/reports/Metadata
ls
quit
EOS
`

echo "Old: $newMeta"
echo "New: $MetadataFull"

# 更新されており、サーバダウンでない場合は次に進む。そうでなければ終了。
if [ $newMeta != "$MetadataFull" -a "$MetadataFull" != "" ]; then
  echo "Updated."
else
  echo "Not updated."
  exit
fi
  


# 最新のメタデータの作成
# chipome_ver3/lib/metadata/NCBI_SRA_Metadata_Full_20150101.metadata.tab が作られる。
sh $projectDir/sh/metaPrep.sh $projectDir

newMeta=`ls $projectDir/lib/metadata/NCBI_SRA_Metadata_Full_2*.metadata.tab| sort| tail -n1`            # 最新版
oldMeta=`ls $projectDir/lib/metadata/NCBI_SRA_Metadata_Full_2*.metadata.tab| sort| tail -n2| head -n1`  # ひとつ前のバージョン

# newMeta と oldMeta の 2 列目に randStr を挿入 (join 後に file1 と file2 を区別するため)
for fn in $newMeta $oldMeta; do
  rndStr=e2ZstXNCHDZbxPyTuYTN
  awk -v RND=$rndStr -F '\t' '{
    printf "%s\t%s", $1, RND
    for (i=2; i<NF; i++) printf "\t%s", $i
    print "\t" $NF
  }' $fn > $fn.tmp
done


# 変更または新規追加されたものを update に用いる
join -a1 -t $'\t' -1 1 -2 1 $newMeta.tmp $oldMeta.tmp |awk -F '\t' '{
  split($0, arr, "\t"$2"\t")
  new=arr[2]
  old=arr[3]
  gsub("[ \t]", "", arr[2])
  gsub("[ \t]", "", arr[3])
  if (arr[2] != arr[3]) print $1 "\t" new
}' > $projectDir/lib/metadata/NCBI_SRA_Metadata_Full_for_update.metadata.tab

cut -f1 $projectDir/lib/metadata/NCBI_SRA_Metadata_Full_for_update.metadata.tab > $projectDir/lib/metadata/SRXsForDelete.tab

# 削除されたものを見つける
join -v2 -t $'\t' -1 1 -2 1 $newMeta $oldMeta| cut -f1 >> $projectDir/lib/metadata/SRXsForDelete.tab


# 変更または削除されたものについて、これまでの result を消去する。
QVAL=`cat $projectDir/sh/preferences.txt| awk -F '\t' '$1 == "qVal" {print $2}'`
{
  echo $projectDir/results/*/BigWig/*RX*.bw
  echo $projectDir/results/*/log/*RX*.log.txt
  echo $projectDir/results/*/metadata/*RX*.meta.txt
  echo $projectDir/results/*/summary/*RX*.txt
  echo $projectDir/results/*/Bed*/Bed/*RX*.*.bed
  echo $projectDir/results/*/Bed*/BigBed/*RX*.*.bb
}| tr ' ' '\n'| tr '/.' '  '| awk '{
  for (i=4; i<=NF; i++) if ($i ~ /[DES]RX[0-9][0-9]/) print $3 "\t" $i
}'| awk '!a[$0]++'| awk -v delList="$projectDir/lib/metadata/SRXsForDelete.tab" -v QVAL="$QVAL" -v pd=$projectDir '
BEGIN {
  while ((getline < delList) > 0) x[$1]++
  N = split(QVAL, q, " ")
} x[$2] > 0 {
  printf "rm"
  printf " " pd "/results/" $1 "/BigWig/" $2 ".bw"
  printf " " pd "/results/" $1 "/log/" $2 ".log.txt"
  printf " " pd "/results/" $1 "/metadata/" $2 ".meta.txt"
  printf " " pd "/results/" $1 "/summary/" $2 ".txt"
  for (i=1; i<=N; i++) {
    printf " " pd "/results/" $1 "/Bed" q[i] "/Bed/" $2 "." q[i] ".bed"
    printf " " pd "/results/" $1 "/Bed" q[i] "/BigBed/" $2 "." q[i] ".bb"
  }
  printf "\n"
}'| sh

rm $newMeta.tmp $oldMeta.tmp
rm $projectDir/lib/metadata/SRXsForDelete.tab


# Controller.sh を実行
GENOME=`ls $projectDir/results/| tr '\n' ' '`
QVAL=$(ls $projectDir/results/`ls $projectDir/results/| head -n1`| grep Bed| cut -c 4-| tr '\n' ' ')

qsub -l d_rt=1440:00:00 -l s_rt=1440:00:00 $projectDir/sh/Controller.sh "$GENOME" $projectDir "$QVAL" $projectDir/lib/metadata/NCBI_SRA_Metadata_Full_for_update.metadata.tab
# $1 ゲノム (例 "hg19 mm9 ce10 dm3 sacCer3")
# $2 projectDir (例 chipome_ver3)
# $3 Qval (例 "05 10 20")
# $4 メタデータ (例 NCBI_SRA_Metadata_Full_for_update.metadata.tab)


