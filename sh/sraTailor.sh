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
SorD=`echo $SRX| tr -d '[0-9]'`
SRX_short=`echo $SRX | cut -b 1-6`
mkdir -p $projectDir/results/$Genome/$bn
ResDir=$projectDir/results/$Genome/$bn
declare -A size                # -Aでハッシュ宣言 
PastT=`date +%s`

fastqDump=/home/$LoginID/$projectDir/bin/sratoolkit.2.3.2-4-ubuntu64/bin/fastq-dump
bowtie2=/home/$LoginID/$projectDir/bin/bowtie2-2.2.2/bowtie2
samtools=/home/$LoginID/$projectDir/bin/samtools-0.1.19/samtools
macs2=/home/$LoginID/$projectDir/bin/MACS2-2.1.0/$projectDir/bin/MACS2-2.1.0/bin/macs2
bedtools=/home/$LoginID/$projectDir/bin/bedtools-2.17.0/bin/bedtools
bedGraphToBigWig=/home/$LoginID/$projectDir/bin/bedGraphToBigWig
bedClip=/home/$LoginID/$projectDir/bin/bedClip
bedToBigBed=/home/$LoginID/$projectDir/bin/bedToBigBed


####################################################################################################
#                                             Asprea
####################################################################################################
echo -e "\nJob ID = $JOB_ID\n"
echo -e "\nsra ファイルのダウンロード中...\n"

/home/$LoginID/.aspera/connect/bin/ascp -QT -i /home/$LoginID/.aspera/connect/etc/asperaweb_id_dsa.openssh  -L $ResDir -k 1 -l 100000000 \
anonftp@ftp-trace.ncbi.nlm.nih.gov:/sra/sra-instant/reads/ByExp/sra/$SorD/$SRX_short/$SRX $ResDir

mv $ResDir/$SRX/*RR*/*RR* $ResDir
cd $ResDir
SRR=`ls [DSE]RR* | head -n1| cut -d '.' -f1`
SorP=`curl "http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?cmd=viewer&m=data&s=viewer&run="$SRR| grep -A10 Layout |grep "<td>PAIRED"|wc -l` # SorP=0: SINGLE, 1: PAIRED

echo -e "\nsra ファイルのダウンロードが完了しました。\n"

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

for SRAs in `ls| grep ".sra"`; do
  SRAfn=`echo $SRAs| cut -d '.' -f1`
  $fastqDump $Split -A $SRAfn /home/$LoginID/$ResDir/$SRAfn.sra &
  WaitNum=$WaitNum" "$!
done
wait $WaitNum

rm *.log
rm -r [DSE]RX*
rm *.sra

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

rm [DSE]RR*.fastq     #########

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
esac

echo -e "\nBed ファイルを作成中...\n"

MACS() { # $1=Qval
  export PYTHONPATH=/home/$LoginID/$projectDir/bin/MACS2-2.1.0/$projectDir/bin/MACS2-2.1.0/lib/python2.7/site-packages:$PYTHONPATH
  BN=$bn.$1
  $macs2 callpeak -t $bn.bam -f BAM -g $macsg -n $BN -q 1e-$1
  cat $BN"_"peaks.narrowPeak | sort -k1,1 -k2,2n > $BN"_"peaks.unclip   # cut -f1-3,5 は後回し
  $bedClip $BN"_"peaks.unclip /home/$LoginID/$projectDir/lib/genome_size/$Genome.chrom.sizes $BN.bed
  awk '{printf "%s\t%s\t%s\t%.1f\n", $1, $2, $3, $5/10}' $BN.bed > $BN.bed.tmp
  $bedToBigBed -type=bed4 $BN.bed.tmp /home/$LoginID/$projectDir/lib/genome_size/$Genome.chrom.sizes $BN.bb
  rm $BN"_"model.r $BN"_"*.xls $BN"_"peaks.narrowPeak $BN"_"peaks.unclip $BN.bed.tmp
  echo CompletedMACS2peakCalling
}

for i in `echo $qVal`; do
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


