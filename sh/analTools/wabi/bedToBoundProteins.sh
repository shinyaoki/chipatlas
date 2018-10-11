#!/bin/sh
#$ -S /bin/sh

# sh chipatlas/sh/analTools/bedToBoundProteins.sh A.bed B.bed L.bed out.tsv

# 入力ファイルが Bed か motif かを判定し、motif ならば Bed に変換する
function motifOrBed () {  # $1 = 入力 Bed ファイル名  $2 = Genome
  inBed=$1
  genomeForMotifOrBed=$2
  mb=`cat $inBed| awk '{
    if ($1 ~ /^chr/) {
      print >> "tmpForMotifOrBed"
      i++
    }
  } END {
    printf "%d", i
  }'`
  if [ $mb = "0" ]; then     # 入力が motif の場合、Bed に変換
    motif=`cat $inBed| sed 's/[^a-zA-Z]//g'`
    /home/w3oki/bin/motifbed $motif $genomeForMotifOrBed > "tmpForMotifOrBed"
  fi
  mv tmpForMotifOrBed $inBed
}


# 入力ファイルの遺伝子名を Bed に変換する
function geneToBed () {  # $1 = 入力 Bed ファイル名  $2 = Genome  $3 = distanceUp  $4 = distanceDown
  inGene=$1
  genomeForGeneToBed=$2
  upBp=$3
  dnBp=$4
  tssList="/home/w3oki/chipatlas/lib/TSS/uniqueTSS."$genomeForGeneToBed".bed"
  cat $tssList| awk -v inGene=$inGene -v upBp=$upBp -v dnBp=$dnBp '
  BEGIN {
    while ((getline < inGene) > 0) {
      gsub(/[^a-zA-Z0-9\t_\n]/, "_", $1)
      g[tolower($1)]++
    }
    close(inGene)
  } {
    gene = $4
    gsub(/[^a-zA-Z0-9\t_\n]/, "_", $4)
    if (g[tolower($4)] > 0) {
      beg = ($5 == "+")? $2 - upBp : $3 - dnBp
      end = ($5 == "+")? $2 + dnBp : $3 + upBp
      if (beg < 1) beg = 1
      printf "%s\t%s\t%s\t%s\n", $1, beg, end, gene
    }
  }' > tmpForGeneToBed
  mv tmpForGeneToBed $inGene
}


# パラメータの取得, 変数宣言
descriptionA="My data"
descriptionB="Comparison"
title="My data vs Comparison"
hed="Search for proteins significantly bound to your data."
wabiID=`cat job_info.json| tr -d '"":,'| awk '$1 == "requestId" {printf "%s", $2}'`
srxUrl="http://chip-atlas.org/view?id="



for VAR in bedA bedB outTsv outHtml typeA typeB descriptionA descriptionB title permTime distanceDown distanceUp genome antigenClass cellClass threshold; do
  eval $VAR='$'1
  eval echo $VAR "=" '$'1
  shift
done

for fn in $bedA $bedB; do
  cat $fn| tr -d '\015' > tmpForinBed
  mv tmpForinBed $fn
done

# typeA : "BED" / "gene"
# typeB : "random" / "userBED" / "RefSeq" / "userGenes"

# typeA : "bed" / "gene"
# typeB : "rnd" / "bed" / "refseq" / "userlist"


expL="/home/w3oki/chipatlas/lib/assembled_list/experimentList.tab"
filL="/home/w3oki/chipatlas/lib/assembled_list/fileList.tab"
tmpF="$outF.tmpForbedToBoundProteins"
outTsv="wabi_result.tsv"
outHtml="wabi_result.html"
shufN=1


# タイプごとに入力ファイルを処理
case $typeA in
  "bed")  # TypeA = BED の場合、モチーフは BED に、BED はそのまま。
    motifOrBed $bedA $genome
    case $typeB in
      "rnd")  # TypeB = random の場合、bedtools shuffle を行う
        for i in `seq $permTime`; do
          bedtools shuffle -i $bedA -g /home/w3oki/chipatlas/lib/genome_size/$genome.chrom.sizes
        done > $bedB
        shufN=$permTime
        ;;
      "bed")  # TypeB = BED の場合、モチーフは BED に、BED はそのまま。
        motifOrBed $bedB $genome
        ;;
    esac
    ;;
  "gene")  # TypeA = gene の場合、geneA を BED に変換
    geneToBed $bedA $genome $distanceUp $distanceDown
    case $typeB in
      "refseq")  # TypeB = RefSeq の場合、geneA 以外の遺伝子を BED に変換
        cat "/home/w3oki/chipatlas/lib/TSS/uniqueTSS."$genome".bed"| awk -v bedA=$bedA '
        BEGIN {
          while ((getline < bedA) > 0) g[$4]++
        } {
          if (g[$4] + 0 < 1) print $4
        }' > $bedB
        geneToBed $bedB $genome $distanceUp $distanceDown
        ;;
      "userlist")  # TypeB = userGenes の場合、そのまま BED に変換
        geneToBed $bedB $genome $distanceUp $distanceDown
        ;;
    esac
    ;;
esac

wclA=`cat $bedA| wc -l`
wclB=`cat $bedB| wc -l`


# ライブラリファイルの選択
bedL=`cat $filL| awk -F '\t' -v genome="$genome" -v antigenClass="$antigenClass" -v cellClass="$cellClass" -v threshold="$threshold" '{
  if ($2 == genome && $3 == antigenClass && $5 == cellClass && $4$6 == "--" && $7 == threshold) {
    printf "/home/w3oki/chipatlas/results/%s/public/%s.bed", genome, $1
  }
}'`   # chipatlas/results/mm9/public/ALL.ALL.05.AllAg.AllCell.bed


# 入力 Bed ファイルをソート
{
  cut -f1-3 $bedA| awk -F '\t' '{print $0 "\tA"}'
  cut -f1-3 $bedB| awk -F '\t' '{print $0 "\tB"}'
}| tr -d '\015'| awk '{print $0 "\t" NR}'| /home/w3oki/bin/qsortBed > $tmpF
#  chr1    3021366 3021399 ERX132628       chr1    3020993 3021399 B       5791830


# bedtools2
for bedL in `ls $bedL.*`; do
  awk '{x[$4]++} END {for (i in x) print i "\t" x[i]}' $bedL >> "$tmpF"3 &
  /home/w3oki/bin/bedtools2/bin/bedtools intersect -sorted -a $bedL -b $tmpF -wb >> "$tmpF"2
done


cat "$tmpF"2| awk -F '\t' -v wclA=$wclA -v wclB=$wclB -v shufN=$shufN '{  # カウント
  if(NR % 1000000 == 0) delete x
  if (!x[$4,$9]++) {
    if ($8 == "A") a[$4]++
    else           b[$4]++
  }
  SRX[$4]++
} END {
  for (srx in SRX) {
    printf "%s\t%d\t%d\t%d\t%d\n", srx, a[srx], wclA - a[srx], int(b[srx] / shufN + 0.5), wclB / shufN -int(b[srx] / shufN + 0.5)
  }
}'| awk '{  # Fisher 検定
  print "echo " $0 " `/home/w3oki/bin/fisher -p " $2 " " $3 " " $4 " " $5 "`"
}'| sh 2>/dev/null| tr ' ' '\t' | awk -F '\t' '{
  for (i=1; i<NF; i++) printf "%s\t", $i
  if ($NF == 0) print "-324"
  else          print log($NF)/log(10)
}'| sort -k6n| /home/w3oki/bin/qval -lL -k6| awk -F '\t' -v expL=$expL '  # Fold enrichment の計算
BEGIN {
  while((getline < expL) > 0) a[$1] = $3 "\t" $4 "\t" $5 "\t" $6
} {
  if (($2+$3)*$4 == 0) FE = "inf"
  else                 FE = ($2/($2+$3))/($4/($4+$5))  # Fold enrichment = (a/ac)/(b/bd)
  printf "%s\t%s\t%s/%s\t%s/%s\t%s\t%s\t%s\n", $1, a[$1], $2, $2+$3, $4, $4+$5, $6, $7, FE
}'| sort -t $'\t' -k8n -k10nr| awk -F '\t' -v tmp="$tmpF"3 '  # 総ピーク数
BEGIN {
  while ((getline < tmp) > 0) peakN[$1] += $2
} {
  if ($2$4 !~ "No description" && $2$4 !~ "Unclassified") {
    for (i=1; i<=5; i++) printf "%s\t", $i
    printf "%d\t", peakN[$1]
    for (i=6; i<=NF; i++) printf "%s\t", $i
    printf "\n"
  }
}'| tee $outTsv| awk -F '\t' -v descriptionA="$descriptionA" -v descriptionB="$descriptionB" -v hed="$hed" -v title="$title" -v wabiID="$wabiID" -v srxUrl=$srxUrl '  # html に変換
BEGIN {
  while ((getline < "/home/w3oki/bin/btbpToHtml.txt") > 0) {
    gsub("___Title___", title, $0)
    gsub("___Targets___", descriptionA, $0)
    gsub("___References___", descriptionB, $0)
    gsub("___Header___", hed, $0)
    gsub("___Caption___", title, $0)
    gsub("___WABIid___", wabiID, $0)
    print
  }
} {
  print "<tr>"
  print "<td title=\"Open this Info...\"><a target=\"_blank\" style=\"text-decoration: none\" href=\"" srxUrl $1 "\">" $1 "</a></td>"
  for (i=2; i<=5; i++) print "<td>" $i "</td>"
  for (i=6; i<=8; i++) printf "<td align=\"right\">%s</td>\n", $i
  for (i=9; i<=10; i++) printf "<td align=\"right\">%.1f</td>\n", $i
  printf "<td align=\"right\">%s</td>\n", ($11 == "inf")? 99999 : sprintf("%.2f", $11)
  printf "<td>%s</td>\n", ($11 > 1 || $11 == "inf")? "TRUE" : "FALSE"
  print "</tr>"
} END {
  print "</tbody>"
  print "</table>"
}' > $outHtml



rm $tmpF "$tmpF"2 "$tmpF"3

#       ある SRX と重なる   重ならない
# bedA              a         c       a+c = bedA の行数 (= wclA)
# bedB              b         d       b+d = bedB の行数 (= wclB)

# Fisher a b c d

# SRX499128   TFs and others    Pou5f1    Pluripotent stem cell   EpiLC   2453   5535/18356    1801/2623   -310.382    -307.491     0.439
# SRX         抗原大             抗原小     細胞大                   細胞小   peak数  a / wclA      b / wclB    p-Val     q-Val (BH)   列7,8のオッズ比










