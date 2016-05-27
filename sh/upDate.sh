#!/bin/sh
#$ -S /bin/sh

# このシェルは以下のコマンドで投入
# sh chipatlas/sh/upDate.sh

if [ "$1" = "" ]; then
  projectDir=`echo $0| sed 's[/sh/upDate.sh[['`
  qsub $projectDir/sh/upDate.sh $projectDir
  exit
fi

####################################################################################################################################
#                                                             以下、qsub モード
####################################################################################################################################


projectDir=$1

newMeta=$(basename `ls $projectDir/lib/metadata/NCBI_SRA_Metadata_Full_2*.metadata.tab| sort| tail -n1`| cut -d '.' -f1) # 所持している最新版

# 最新の MetadataFull の名前を取得
MetadataFull=`ftp -n -v ftp.ncbi.nlm.nih.gov << EOS | grep NCBI_SRA_Metadata_Full_2| awk '{print $9}'| sort| tail -n1| cut -d '.' -f1
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
rm -rf $projectDir/lib/metadata/splitDir
mkdir $projectDir/lib/metadata/splitDir
splitN=`wc -l $projectDir/lib/metadata/SRXsForDelete.tab| awk '{print int($1/100)}'`
split -l $splitN $projectDir/lib/metadata/SRXsForDelete.tab $projectDir/lib/metadata/splitDir/

ql=`sh $projectDir/sh/QSUB.sh mem`
for splitFn in `ls $projectDir/lib/metadata/splitDir/*`; do
  qsub $ql -o /dev/null -e /dev/null -pe def_slot 1 $projectDir/sh/metaDelete.sh $splitFn $projectDir
done

while :; do
  qstatN=`qstat| awk '{if ($3 == "metaDelete") print}'| wc -l`
  if [ $qstatN -eq 0 ]; then
    break
  fi
done

rm $newMeta.tmp $oldMeta.tmp
rm $projectDir/lib/metadata/SRXsForDelete.tab
rm -r $projectDir/lib/metadata/splitDir


# Controller.sh を実行
GENOME=`ls $projectDir/results/| tr '\n' ' '`
QVAL=$(ls $projectDir/results/`ls $projectDir/results/| head -n1`| grep Bed| cut -c 4-| tr '\n' ' ')

qsub $projectDir/sh/Controller.sh "$GENOME" $projectDir "$QVAL" $projectDir/lib/metadata/NCBI_SRA_Metadata_Full_for_update.metadata.tab
# $1 ゲノム (例 "hg19 mm9 ce10 dm3 sacCer3")
# $2 projectDir (例 chipome_ver3)
# $3 Qval (例 "05 10 20")
# $4 メタデータ (例 NCBI_SRA_Metadata_Full_for_update.metadata.tab)


