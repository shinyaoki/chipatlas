
# 圧縮コマンド
projectDir=xhipome_ver3
outDir=$projectDir/tmpDirForArchive
rm -rf $outDir
mkdir $outDir
for Genome in `ls ~/$projectDir/results/`; do
  echo $projectDir/results/$Genome/public/| xargs ls| awk '{
    print rand() "\t" $1
  }'| sort -k1n| awk -v nr=0 -v projectDir=$projectDir -v Genome=$Genome -v outDir=$outDir '{
    nr++
    if (nr == 1) {
      i++
      outFn = outDir "/" Genome "." i 
      printf "cd %s/results/%s/public\n", projectDir, Genome > outFn
      printf "zip ~/%s/tmpDirForArchive/%s_%04d.zip ", projectDir, Genome, i >> outFn
    }
    printf "%s ", $2 >> outFn
    if (nr == 10000) nr = 0
  }'
done


short=`sh $projectDir/sh/QSUB.sh shortOrweek`
for fn in `ls $outDir/*`; do
  echo $fn| awk '{printf "\n cd \n rm %s\n", $1 >> $1}'
  cat $fn| qsub -N targz $short -o /dev/null -e /dev/null
done

# outFn の中身
# cd xhipome_ver3/results/hg19/public
# zip ~/xhipome_ver3/tmpDirForArchive/hg19_0010.zip Oth.Bld.10.AllAg.81-3.bed InP.Dig.05.AllAg.Stomach.bed Oth.Epd.10.FOXP3.AllCell.TT.txt ...
# cd 
# rm xhipome_ver3/tmpDirForArchive/hg19.10


# 解凍コマンド
rm -rf data
mkdir data
for Genome in `ls ~/$projectDir/results/`; do
  mkdir data/$Genome
  mkdir data/$Genome/assembled
done

# 本番
cd data
for fn in `ls tmpDirForArchive/*.zip`; do
  {
    Genome=`basename $fn| cut -d '_' -f1`
    unzip $fn -d $Genome/assembled
#    rm $fn
  } &
done


2.3G	xhipome_ver3/results/ce10/ce10_assembled/
7.6G	xhipome_ver3/results/dm3/dm3_assembled/
272G	xhipome_ver3/results/hg19/hg19_assembled/
149G	xhipome_ver3/results/mm9/mm9_assembled/
315M	xhipome_ver3/results/sacCer3/sacCer3_assembled/

2.0G	tmpDirForTargz/ce10.tar.gz
7.3G	tmpDirForTargz/dm3.tar.gz
264G	tmpDirForTargz/hg19.tar.gz
144G	tmpDirForTargz/mm9.tar.gz
138M	tmpDirForTargz/sacCer3.tar.gz



# 転送コマンド
projectDir=xhipome_ver3
address=ftp2.biosciencedbc.jp
user=upload4
pass=S9wTgHyT

{
  echo "open -u $user,$pass $address"
  echo "mkdir data/tmpDirForArchive"
  for Genome in `ls $projectDir/results`; do
    cat << EOS
      mkdir data/$Genome
      mkdir data/$Genome/assembled
      mkdir data/$Genome/eachData
      mkdir data/$Genome/eachData/bw
      mirror -R --delete --verbose=3 --parallel=1 $projectDir/tmpDirForArchive data/tmpDirForArchive
EOS
    for qVal in `ls $projectDir/results/$Genome/| grep Bed| cut -c4-`; do
      cat << EOS
        mkdir data/$Genome/eachData/bb$qVal
EOS
    done
  done
} > UploadToServer.fltp

lftp -f UploadToServer.fltp

# 金曜日 22:25 転送開始


# テストコマンド for data
mkdir data
mkdir data/tmpDirForArchive
for Genome in ce10  dm3  hg19  mm9  sacCer3; do
  mkdir data/$Genome
  mkdir data/$Genome/assembled
done

for fn in `ls $projectDir/tmpDirForArchive`; do
  cp $projectDir/tmpDirForArchive/$fn data/tmpDirForArchive/$fn &
done

