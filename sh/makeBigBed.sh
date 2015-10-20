#!/bin/sh
#$ -S /bin/sh

mode=0
# qsub -o /dev/null -e /dev/null xhipome_ver3/sh/makeBigBed.sh -i xhipome_ver3
while getopts i option
do
  case "$option" in
  i)
    mode=initial
    ;;
  esac
done
shift `expr $OPTIND - 1`

projectDir=$1
QSUB="sh $projectDir/sh/QSUB.sh"
logDir=makeBigBed_log

####################################################################################################################################
#                                                         初期 モード
####################################################################################################################################
if [ $mode = "initial" ]; then
  rm -rf $logDir
  mkdir $logDir

  # 全ての Bed ファイルをランダムに振り分け、makeBigBed.sh の qsub モードに渡す。
  echo $projectDir/results/*/public/*.bed| xargs ls| awk -v PRD=$projectDir '{
    print rand() "\tsh " PRD "/sh/makeBigBed.sh " PRD " " $1
  }'| sort -k1nr| cut -f2 > $logDir/makeBigBed.list

  splitN=`cat $logDir/makeBigBed.list| wc -l| awk '{print int($1/2000)}'`
  split -a 3 -l $splitN $logDir/makeBigBed.list $logDir/MAKEBIGBEDTMP
  short=`sh $projectDir/sh/QSUB.sh shortOrweek`
  for tmpList in `ls $logDir/MAKEBIGBEDTMP*`; do
    cat $tmpList| qsub $short -N makeBigBed -l s_vmem=8G,mem_req=8G -o $tmpList.log -e $tmpList.log
  done

  # 全部終わったら、サーバにアップロード
  while :; do
    qN=`qstat| awk '{if ($3 == "makeBigBed") print}' | wc -l`
    if [ $qN -eq 1 ]; then
      sh $projectDir/sh/webList.sh $projectDir
exit
      qsub -o UploadToServer.log.txt -e UploadToServer.log.txt $projectDir/sh/UploadToServer.sh $projectDir
      rm -r $logDir
      exit
    fi
  done
fi


####################################################################################################################################
#                                                         以下、qsub モード
####################################################################################################################################
# sh xhipome_ver3/sh/makeBigBed.sh xhipome_ver3 xhipome_ver3/results/hg19/public/Oth.NoD.60.Nr2f2.AllCell.bed

inBed=$2                            # xhipome_ver3/results/hg19/public/ALL.ALL.05.AllAg.AllCell.bed
inBn=`echo $inBed| sed s/.bed$//`   # xhipome_ver3/results/hg19/public/ALL.ALL.05.AllAg.AllCell
Genome=`echo $inBed| sed "s/$projectDir//"| cut -d '/' -f3`
gSize=$projectDir/lib/genome_size/$Genome.chrom.sizes
www=`cat $projectDir/sh/preferences.txt| awk '$1 == "www" {printf "%s", $2}'`

ls -l $inBed

# inBn.bed に含まれるメタデータリスト
for SRX in `cut -f4 $inBn.bed| sed 's/\]_\[/ /g'| tr -d '[]'| cut -d ' ' -f3| awk '!x[$1]++'`; do
  cat $projectDir/results/$Genome/metadata/$SRX.meta.txt
done > $inBn.bed.meta

# inBn=ALL.ALL.05.AllAg.AllCell
# Genome=hg19

# 抗原 $5, 細胞 $7, SRX $9
cat $inBn.bed| tr '[]' '\t\t'| awk -F '\t' -v projectDir=$projectDir -v Genome=$Genome -v meta="$inBn.bed.meta" -v inBn=$inBn -v www="$www" '
function symbolSub(Str,underScore) {
  gsub("%", "%25", Str)   # IGV で表示できない文字 %+;=" space を URL エンコーディング に変換
  gsub("+", "%2B", Str)
  gsub(";", "%3B", Str)
  gsub("=", "%3D", Str)
  gsub("\"", "%22", Str)
  gsub(" ", "%20", Str)
  if (underScore == "_") gsub(underScore, "%20", Str)
  return Str
} BEGIN {
  while ((getline < meta ) > 0) {
    Title[$1] = symbolSub($3,"_")
    sub("xxx", "NA", Title[$1])
    
    for (i=18; i<=NF; i++) {
      sub("=", SUBSEP, $i)
      $i = symbolSub($i)
      split($i, arr, SUBSEP)
      Atrb[$1] = Atrb[$1] arr[1] "=" arr[2] ";"
    }
    SRX = SRX "," $1
  }
  sub(",", "", SRX)
  abbrAg=projectDir "/sh/abbreviationList_AG.tab"
  abbrCt=projectDir "/sh/abbreviationList_CT.tab"
  while ((getline < abbrAg ) > 0) {
    agL[$1] = $2
  }
  while ((getline < abbrCt ) > 0) {
    ctL[$1] = $2
    c[$1] = symbolSub($2,"_")
  }
  
  NumSlash = split(inBn, p, "/")
  split(p[NumSlash], z, ".")
  
  for (i=4; i<=5; i++) {
    gsub("BRACKETL", "(", z[i])
    gsub("BRACKETR", ")", z[i])
    gsub("PERIOD", ".", z[i])
    gsub("_", " ", z[i])
    gsub("SLASH", "/", z[i])
  }
  
  if (z[4] == "AllAg") {
    AG  = z[1]
    agS = "-"
  } else {
    AG  = z[4]
    agS = z[4]
  }
  if (z[5] == "AllCell") {
    CL  = z[2]
    ctS = "-"
  } else {
    CL  = z[5]
    ctS = z[5]
  }
  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", p[NumSlash], Genome, agL[z[1]], agS, ctL[z[2]], ctS, z[3], SRX > inBn ".list"
                                             # ファイル名  ゲノム   抗原大     抗原小  細胞大    細胞小  q-Val SRX
  printf "track name=\"%s (@ %s) %d\" url=\"%s/view?id=$$\" gffTags=\"on\"\n", AG, CL, z[3]*10, www
} {
  if ($7 ~ "_@") {
    sub("_@", SUBSEP, $7)
    split($7, y, SUBSEP)
    cellGroup = c[y[2]]
  } else {
    cellGroup = "NA"  # Unc の場合
    y[1] = $7
  }
  
  SRX = $9
  printf "%s\t%s\t%s\t", $1, $2, $3
  printf "ID=%s;", SRX
  printf "Name=%s%20", symbolSub($5,"_")
  printf "(@%20"
  printf "%s", symbolSub(y[1],"_")
  printf ");"
  printf "Title=%s;", Title[SRX]
  printf "%s%s;", "Cell%20group=", cellGroup
  printf "<br>%s\t", Atrb[SRX]
  printf "%s\t%s\t%s\t%s\t%s\n", $11, $12, $13, $14, $15
}' > $inBn.bed.tmp


# Bed index の作成

#echo "BedGraph 作成中"
#$projectDir/bin/bedtools-2.17.0/bin/bedtools genomecov -i $inBn.bed -bg -g $gSize > $inBn.bg
#echo "BigWig 作成中"
#$projectDir/bin/bedGraphToBigWig $inBn.bg $gSize $inBn.bw
#rm $inBn.bg 
rm $inBn.bed.meta
echo "Bed index 作成中"
mv $inBn.bed.tmp $inBn.bed
java -Xmx2000m -Djava.awt.headless=true -jar $projectDir/bin/IGVTools/igvtools.jar index $inBn.bed









