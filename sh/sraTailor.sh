#!/bin/sh
#$ -S /bin/sh

# --------------------------------
# $1 SRX (例: SRX023509)
# $2 Genome  (例: mm9)
# $3 $projectDir (例: chipome_ver3)
# $4 q-val threshold (例: "05 10 20")

# qsub -N "srT$Genome" -o $Logfile -e $Logfile -pe def_slot $nslot $projectDir/sh/sraTailor.sh $SRX $Genome $projectDir "$QVAL"
# --------------------------------

SorP=0
SRX=$1
Genome=$2
projectDir=$3
qVal=$4
LoginID=`whoami`
bn=$SRX
ResDir=$projectDir/results/$Genome/$bn
declare -A size                # -Aでハッシュ宣言 
PastT=`date +%s`
module load singularity

fastqDump=/home/$LoginID/$projectDir/bin/sratoolkit.2.9.4-ubuntu64/bin/fasterq-dump
fasterqDump=/home/$LoginID/$projectDir/bin/sratoolkit.2.9.6-1-ubuntu64/bin/fasterq-dump
bowtie2=/home/$LoginID/$projectDir/bin/bowtie2-2.2.2/bowtie2
samtools=/home/$LoginID/$projectDir/bin/samtools-0.1.19/samtools
# macs2="/usr/local/biotools/m/macs2:2.1.1--r3.2.2_0 macs2"


bedtools=/home/$LoginID/$projectDir/bin/bedtools-2.17.0/bin/bedtools
bedGraphToBigWig=/home/$LoginID/$projectDir/bin/bedGraphToBigWig
bedClip=/home/$LoginID/$projectDir/bin/bedClip
bedToBigBed=/home/$LoginID/$projectDir/bin/bedToBigBed

logF="$projectDir/results/$Genome/log/$SRX.log.txt"
: > "$logF"
rm -rf $ResDir
mkdir $ResDir

####################################################################################################
#                                             Asprea
####################################################################################################
echo -e "\nJob ID = $JOB_ID\n"
echo -e "\nsra ファイルのダウンロード中...\n"


cat << '===================' > /dev/null # 2017/11/13 以前は web サイトにアクセスし、ラン情報を取得
for srr in `curl -s "https://www.ncbi.nlm.nih.gov/sra?term=$SRX"| awk '$0 ~ "<div>Layout: <span>" {
  gsub("?run=", "\n")
  gsub("\"", "\t")
  print
}'| awk '{
  if (NR == 1) print sub("<span>PAIRED</span>", "")
  else if ($1 ~ /[DES]RR[0-9][0-9]/) print $1
}'`; do
  if [ `echo $srr| wc -c` = 2 ] ; then
    SorP=$srr # SorP=0: SINGLE, 1: PAIRED
  else
    SorD=`echo $srr| tr -d '[0-9]'`
    SRR_short=`echo $srr | cut -b 1-6`
    /home/$LoginID/.aspera/connect/bin/ascp -QT -i /home/$LoginID/.aspera/connect/etc/asperaweb_id_dsa.openssh -L $ResDir -k 1 -l 100000000 \
    anonftp@ftp-trace.ncbi.nlm.nih.gov:/sra/sra-instant/reads/ByRun/sra/$SorD/$SRR_short/$srr/$srr.sra $ResDir/$srr.sra
  fi
done
===================

# SorP=0: SINGLE, 1: PAIRED
runInfo=`cat $projectDir/lib/metadata/SRA_Metadata_RunInfo.tab| awk '$1 == "'$SRX'"'`
SorP=`echo $runInfo| cut -d ' ' -f2`

cat << '===================' > /dev/null # 2019/05/31 以前は aspera でダウンロード
for srr in `echo $runInfo| cut -d ' ' -f3-`; do
  SorD=`echo $srr| tr -d '[0-9]'`
  SRR_short=`echo $srr | cut -b 1-6`
  /home/$LoginID/.aspera/connect/bin/ascp -QT -i /home/$LoginID/.aspera/connect/etc/asperaweb_id_dsa.openssh -L $ResDir -k 1 -l 100000000 \
  anonftp@ftp-trace.ncbi.nlm.nih.gov:/sra/sra-instant/reads/ByRun/sra/$SorD/$SRR_short/$srr/$srr.sra $ResDir/$srr.sra
done

echo $runInfo| awk 'NF < 3 {print "NO_RUN_INFO"}'
NRI=`cat $logF| grep -c NO_RUN_INFO`
if [ $NRI -gt 0 ]; then
  rm -rf $ResDir
  exit
fi

sleep 10
Nstop=`cat $logF| grep -c -e "Session Stop" -e "ascp: "`
Nnone=`cat $logF| grep -c -e "Server aborted session: No such file or directory" -e "Completed: 0K bytes"`


if [ $Nstop -gt 0 ]; then  # 通信障害の場合、再投稿
  if [ $Nnone -eq 0 ]; then
    ql=`sh $projectDir/sh/QSUB.sh mem`
    rm -f $logF
    rm -rf $ResDir
    qsub -N "srT$Genome" -o $logF -e $logF -pe def_slot $NSLOTS $ql $projectDir/sh/sraTailor.sh $SRX $Genome $projectDir "$qVal"
    exit
  else  # SRA がない場合は強制終了
    echo NO_SRA_FOUND
    rm -rf $ResDir
    exit
  fi
fi

cd $ResDir
echo -e "\nsra ファイルのダウンロードが完了しました。\n"
===================

if [ $SorP = "0" ] ; then
  echo "Read layout: SINGLE"
  optRmdup="-s"
else
  echo "Read layout: PAIRED"
  Split="--split-files"
fi


####################################################################################################
#                                             fastq-dump
####################################################################################################
echo ""
echo -e "\nfastq に変換中...\n"

cat << '===================' > /dev/null # 2019/05/31 以降は fasterq-dump
function fqd_error() {
  while :; do
    errN=`cat $1| grep -c -e "timeout exhausted while creating" -e "connection failed while opening"`
    sucN=`cat $1| grep -c "Time loading reference"`
    if [ $errN -gt 0 ]; then
      echo "fastq-dump エラーにより強制終了します。"
      rm -rf $2
      qdel $3
    fi
    if [ $sucN -gt 0 ]; then
      break
    fi
    sleep 100
  done
}

# fqd_error /home/$LoginID/$projectDir/results/$Genome/log/$SRX.log.txt /home/$LoginID/$ResDir $JOB_ID &
for SRAs in `ls| grep ".sra"`; do
  SRAfn=`echo $SRAs| cut -d '.' -f1`
  mv $SRAs $SRAfn
  /home/$LoginID/bin/nt "$fastqDump -O ~/$ResDir -t ~/$ResDir/fastqDump_tmp_$SRAfn $Split $SRAfn" &
  WaitNum=$WaitNum" "$!
  sleep 1
done
wait $WaitNum

rm *.log
===================

echo $runInfo| awk 'NF < 3 {print "NO_RUN_INFO"}'
NRI=`cat $logF| grep -c NO_RUN_INFO`
if [ $NRI -gt 0 ]; then
  rm -rf $ResDir
  exit
fi

cd $ResDir
requsub="qsub -N srT$Genome -o $logF -e $logF -pe def_slot $NSLOTS $projectDir/sh/sraTailor.sh $SRX $Genome $projectDir \""$qVal"\""
unavCmd='curl -s "https://www.ncbi.nlm.nih.gov/sra/?term='$SRX'"| grep -c '\''<td colspan="3" align="center">unavailable</td>'\'''
for srr in `echo $runInfo| cut -d ' ' -f3-`; do
  while :; do
    ~/chipatlas/bin/sratoolkit.2.9.6-1-ubuntu64/bin/fasterq-dump $Split -f $srr 2>&1| awk -v unavCmd="$unavCmd" '{
      print $0
      if ($0 ~ "fasterq-dump.2.9.6 err: row") {  # このエラーは混線時に表示され、fasterq-dump が終了してしまうため、再実行させる
        cmd = "cd; rm -rf '"$ResDir"'; '"$requsub"'; qdel '$JOB_ID'"
        system(cmd)
      }
      if ($0 ~ "fasterq-dump.2.9.6 err: invalid accession") {  # .sra が存在しないとき、このエラーが延々と出て終了しないので、.sra がないことを確認して qdel させる。
        unavCmd | getline var
        if (var > 0) cmd = "cd; rm -rf '"$ResDir"'; qdel '$JOB_ID'"  # invalid accession は .sra が存在する場合にも出るが、その場合は放置して良い。
        system(cmd)
      }
      if ($0 ~ "err: query unauthorized while resolving query within virtual file system module") { # human sequence が非公開の場合は強制終了。
        cmd = "cd; rm -rf '"$ResDir"'; qdel '$JOB_ID'"
        system(cmd)
      }
    }'
    ls $srr*fastq > /dev/null 2>&1 && break
  done
done

lfq=`ls -1 *.fastq | wc -l`
ls -1 *.fastq | awk -v Lfq="$lfq" -v BN=$bn -v SORP="$SorP" '{
  if (SORP == 0) {  #SINGLE
    if (Lfq == 1) print "mv " $1 " " BN ".fq"
    else print "cat " $1 " >> " BN ".fq"
  }
  else {   #PAIRED
    if (Lfq == 2) {
      if ($1 ~ /_1.fastq$/) print "mv " $1 " " BN "_1.fq"
      if ($1 ~ /_2.fastq$/) print "mv " $1 " " BN "_2.fq"
    }
    else {
      if ($1 ~ /_1.fastq$/) print "cat " $1 " >> " BN "_1.fq"
      if ($1 ~ /_2.fastq$/) print "cat " $1 " >> " BN "_2.fq"
    }
  }
}' |/bin/sh

rm [DSE]RR*     #########
# rm -r fastqDump_tmp*
for srr in `echo $runInfo| cut -d ' ' -f3-`; do
  rm /home/$LoginID/ncbi/public/sra/$srr.sra.cache
done

if [ $SorP = "0" ] ; then
  size["fastq"]=`ls -l $bn.fq| awk '{print $5}'`
else
  size["fastq"]=`ls -l $bn"_1.fq"| awk '{print $5}'`
fi

echo -e "\nfastq に変換しました。\n"

####################################################################################################
#                                             Bowtie2
####################################################################################################
echo -e "\nbowtie でマッピング中...\n"

if [ $SorP = "0" ] ; then
  $bowtie2 -p $NSLOTS -t --no-unal -x /home/$LoginID/$projectDir/lib/bowtie_index/$Genome -q $bn.fq -S $bn.sam 2> bowtieReport.txt
else
  $bowtie2 -p $NSLOTS -t --no-unal -x /home/$LoginID/$projectDir/lib/bowtie_index/$Genome -q -1 $bn"_1.fq" -2 $bn"_2.fq" -S $bn.sam 2> bowtieReport.txt
fi

rm *.fq

cat bowtieReport.txt
size["Nspots"]=`cat bowtieReport.txt | tr -d '%' | awk '{if ($0 ~ "reads; of these") printf "%d", $1}'`
size["sam"]=`ls -l $bn.sam| awk '{print $5}'`
rm bowtieReport.txt


echo -e "\nマッピングが完了しました。\n"

####################################################################################################
#                                             SamTools
####################################################################################################
echo -e "\nsamtools でBAM に変換中...\n"

$samtools view -@ $NSLOTS -S -b -o $bn.bam_unsrt $bn.sam
rm $bn.sam
$samtools sort -@ $NSLOTS $bn.bam_unsrt $bn.dup
rm $bn.bam_unsrt 
$samtools rmdup $optRmdup $bn.dup.bam $bn.bam

size["NbeforeRmdup"]=`$samtools view -c $bn.dup.bam`
size["NafterRmdup"]=`$samtools view -c $bn.bam`
size["alPercent"]=`echo ${size["NafterRmdup"]} ${size["Nspots"]}| awk '{printf "%f", 100*$1/$2}'`


size["dupPercent"]=`echo ${size["NafterRmdup"]} ${size["NbeforeRmdup"]}| awk '{printf "%f", 100*($2-$1)/$2}'`


size["Bam"]=`ls -l $bn.bam| awk '{print $5}'`
ScaleVal=`echo ${size["NafterRmdup"]} | awk '{printf "%.10f", 1000000/$1}'`
rm $bn.dup.bam
echo -e "\nBAM に変換しました。\n"

####################################################################################################
#                                             Peak-call
####################################################################################################
case "$Genome" in
  mm10 | mm9 | mm8) macsg=mm;;
  hg19 | hg18) macsg=hs;;
  ce10 | ce6) macsg=ce;;
  dm3 | dm2) macsg=dm;;
  sacCer2 | sacCer3) macsg=12100000;;
  rn6) macsg=2.15e9;;  # total genome size (= 2.87e9) の 75%
esac

echo -e "\nBed ファイルを作成中...\n"

MACS() { # $1=Qval
#  export PYTHONPATH=/home/$LoginID/$projectDir/bin/MACS2-2.1.0/$projectDir/bin/MACS2-2.1.0/lib/python2.7/site-packages:$PYTHONPATH
  BN=$bn.$1
  wd="/home/$LoginID/$projectDir/results/$Genome/$SRX/"
  singularity exec /home/$LoginID/$projectDir/bin/macs2:2.1.1--r3.2.2_0 macs2 callpeak -t $wd$bn.bam -f BAM -g $macsg -n $wd$BN -q 1e-$1

#  $macs2 callpeak -t $bn.bam -f BAM -g $macsg -n $BN -q 1e-$1
  cut -d '/' -f1,8 $wd$BN"_"peaks.narrowPeak| tr -d '/'| sort -k1,1 -k2,2n > $wd$BN"_"peaks.unclip   # cut -f1-3,5 は後回し
  $bedClip $wd$BN"_"peaks.unclip /home/$LoginID/$projectDir/lib/genome_size/$Genome.chrom.sizes $wd$BN.bed
  awk '{printf "%s\t%s\t%s\t%s\n", $1, $2, $3, $5}' $wd$BN.bed > $wd$BN.bed.tmp
  $bedToBigBed -type=bed4 $wd$BN.bed.tmp /home/$LoginID/$projectDir/lib/genome_size/$Genome.chrom.sizes $wd$BN.bb
  rm $wd$BN"_"model.r $wd$BN"_"*.xls $wd$BN"_"peaks.narrowPeak $wd$BN"_"peaks.unclip $wd$BN.bed.tmp
  echo CompletedMACS2peakCalling
}

for i in `echo $qVal`; do
  sleep 1
  MACS $i &
  wn="$wn $!"
done


####################################################################################################
#                                             BedGraph
####################################################################################################
echo -e "\nBedGraph に変換中...\n"
$bedtools genomecov -scale $ScaleVal -ibam $bn.bam -bg -g /home/$LoginID/$projectDir/lib/genome_size/$Genome.chrom.sizes > $bn.bg
echo -e "\nBedGraph に変換しました。\n"

size["BedGraph"]=`ls -l $bn.bg| awk '{print $5}'`

####################################################################################################
#                                             BigWig
####################################################################################################
echo -e "\nBigWig に変換中...\n"
$bedGraphToBigWig $bn.bg /home/$LoginID/$projectDir/lib/genome_size/$Genome.chrom.sizes $bn.bw
size["BigWig"]=`ls -l $bn.bw| awk '{print $5}'`
rm $bn.bg

echo -e "\nBigWig に変換しました。\n"


QvalNum=`echo $qVal| awk '{print NF}'`
while :; do
  macsN=`grep -c "CompletedMACS2peakCalling" /home/$LoginID/$projectDir/results/$Genome/log/$SRX.log.txt`
  erroN=`grep -c "Since the d (0) calculated" /home/$LoginID/$projectDir/results/$Genome/log/$SRX.log.txt`

  if [ $macsN -eq $QvalNum ]; then    # MACS2 が正常終了
    break
  elif [ $erroN -gt 0 ]; then  # MACS2 が "Since the d (0) calculated" エラーの場合、強制終了
    kill $wn
    break
  fi
done


for i in `echo $qVal`; do
  size["BedP$i"]=`ls -l $bn"."$i".bed"| awk '{print $5}'`
  mv $bn"."$i".bed" /home/$LoginID/$projectDir/results/$Genome/Bed$i/Bed/
  mv $bn"."$i".bb" /home/$LoginID/$projectDir/results/$Genome/Bed$i/BigBed/
  bedidx=$bedidx" BedP"$i
done
rm $bn.bam

mv $bn.bw /home/$LoginID/$projectDir/results/$Genome/BigWig

cd
rm -r $ResDir


cat $logF| awk '$0 ~ "51020_peaks.narrowPeak" { # まれに変な bed ができることがあるので、その場合は再実行
  cmd = "'"$requsub"'; qdel '$JOB_ID'"
  system(cmd)
}'

CurT=`date +%s`
size["Time"]=`echo "$CurT $PastT" | awk '{printf "%.2f\n", ($1-$2)/60}'`

{
  echo -ne "$SRX\t$SorP"
# for idx in fastq sam Nspots NafterRmdup alPercent dupPercent Bam BedGraph BigWig BedP5 BedP10 BedP20 Time; do
  for idx in fastq sam Nspots NafterRmdup alPercent dupPercent Bam BedGraph BigWig `echo $bedidx` Time; do
    echo -ne "\t${size[$idx]}"
  done
  echo ""
} > $projectDir/results/$Genome/summary/$SRX.txt

exit
# $1 = SRX
# $2 = Single or Paired
# $3 = FastQ サイズ
# $4 = Sam サイズ
# $5 = Nspots
# $6 = NafterRmdup
# $7 = alPercent
# $8 = dupPercent
# $9 = Bam サイズ
# $10= BedGraph サイズ
# $11= BigWig サイズ
# $12= Bed05 サイズ
# $13= Bed10 サイズ
# $14= Bed20 サイズ
# $15= Time


