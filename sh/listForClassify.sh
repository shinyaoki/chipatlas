#!/bin/sh
#$ -S /bin/sh

# このシェルは以下のコマンドで投入
# sh xhipome_ver3/sh/listForClassify.sh

if [ "$1" = "" ]; then
  projectDir=`echo $0| sed 's[/sh/listForClassify.sh[['`
  qstat| awk '$3 == "TimeCourse" && $4 == "okishinya" {print "qdel " $1}'| sh
  QSUB="sh $projectDir/sh/QSUB.sh"
  for Genome in `ls $projectDir/results`; do
    $QSUB -o /dev/null -e /dev/null $projectDir/sh/listForClassify.sh $projectDir $Genome
  done
  exit
fi

####################################################################################################################################
#                                                             以下、qsub モード
####################################################################################################################################
projectDir=$1
Genome=$2

smallestQ=`ls $projectDir/results/$Genome/| grep Bed[0-9]| tr -d Bed|sort -n|head -n1` # 例 05
tagDir=$projectDir/results/$Genome/tag
rm -rf $tagDir
mkdir $tagDir
mkdir -f

# 英数字以外で用いられる文字
# µ́ ³¼»­¾¥ɛ–—⁰�∆≥ﬁ＇﻿Ⅱ‑!"#%&'()*+,-./:;=?@\^_`{|}~，．´¨‐…‘’“”（）
# −±×÷°′″℃¢£△→¬¶ΒΔΦΩαβγδκλμσφАМСб¸¯˚¡¦º©®™¤ÆØæıøßÁÀÄÂĄÅÃÈÊÌÎÑÖÕŔŠáàäâăąåãčçéèêęíïñóöôřúüûý
# IGV で表示できないものは URL エンコーディングに変換
#  % > %25
#  + > %2B
#  ; > %3B
#  = > %3D
#  " > %22


for SRX in `cat $projectDir/results/$Genome/summary/*txt| awk '{if ($3 > 0) printf "%s ", $1}'`; do # FastQ サイズがゼロでないBed を入力
  cat $projectDir/results/$Genome/metadata/$SRX.meta.txt| sed 's/[^0-9a-zA-Z\t"#%&\(\)'\''*+,-./:;=?\^_{}~" ]//g'|tr -d '"'| awk -F '\t' -v Dir=$tagDir -v PD=$projectDir ' #"
                                                                  # 削除される記号は @ † ‡ § ¶ ダブルクオート パイプ など。 この時点でスペースはそのまま。
  BEGIN {
    agAttributes = PD"/sh/ag_attributes.txt"
    ctAttributes = PD"/sh/ct_attributes.txt"
    while ((getline < agAttributes) > 0) {
      nrAb++
      ab[nrAb] = $1
    }
    close(agAttributes)
    while ((getline < ctAttributes) > 0) {
      nrCl++
      cl[nrCl] = $1
    }
    close(ctAttributes)
  } {
    for (i=18; i<=NF; i++) {
      split($i, atribute, "=")
      for (j=1; j<=nrAb; j++) if (atribute[1] == ab[j]) AB[j] = atribute[2]   # 抗体名の取得
      for (j=1; j<=nrCl; j++) if (atribute[1] == cl[j]) CL[j] = atribute[2]   # 細胞組織名の取得
    }
    # 抗体名の決定
    arr["Ab"] = "ND"
    if ($4 == "DNase-Hypersensitivity") {
      arr["Ab"] = "DNase-seq"
    }
    else {
      for (i=1; i<=nrAb; i++) {
        if (AB[i] != "") {
          a++
          allAb = allAb "|" AB[i]
          if (a == 1) arr["Ab"] = AB[i]
        }
      }
    }
    # 細胞組織名の決定
    arr["Cell"]="ND"
    for (i=1; i<=nrCl; i++) {
      if (CL[i] != "") {
        c++
        allCell = allCell "|" CL[i]
        if (c == 1) arr["Cell"] = CL[i]
      }
    }
    # タイトルの決定
    if ($3 != "xxx") arr["Tytle"] = $3
    else             arr["Tytle"] = "ND"
    # タイトルから GSMxxx を除く
    if (substr(arr["Tytle"], 1, 3) == "GSM") {
      arr["Tytle"]=substr(arr["Tytle"], match(arr["Tytle"], /_/)+1)
    }
    # 特殊符合を除く
    for( key in arr) {
      gsub("&lt;", "<", arr[key])
      gsub("&gt;", ">", arr[key])
      gsub("&amp;", "and", arr[key])
    }
    # 長いタイトルを短縮
    fullTtle = arr["Tytle"]
    if (length(arr["Tytle"]) > 50) longTytle=substr(arr["Tytle"], 1, 47)"..."
    else                           longTytle=arr["Tytle"]
    # 長い抗体、細胞、タイトルを短縮
    for( key in arr) {
      if (length(arr[key]) > 25) arr[key]=substr(arr[key], 1, 22)"..."
    }
    # 全属性の整理
    if (sub("\\|", "", allAb) == 0) allAb = "NoAb"
    if (arr["Ab"] == "DNase-seq") allAb = "DNase-seq"
    if (sub("\\|", "", allCell) == 0) allCell = "NoCell"
    # 出力
    print $1 "\t" $12 "\t" fullTtle "\t" longTytle "\t" allAb "\t" arr["Ab"] "\t" allCell "\t" arr["Cell"] "\t" $4  > Dir"/"$1".tag.txt"
    # 例: SRX021071	H9_Oct4_technical_replicate_2	H9_Oct4_technical_replicate_2	Oct4	Oct4	Embyonic_stem_cells	Embyonic_stem_cells	ChIP-Seq
      # $1 = SRX
      # $2 = SRA
      # $3 = フルタイトル (GSM 除く)
      # $4 = 短縮タイトル (50 字以内)
      # $5 = 抗原抗体フル (パイプ 区切り)
      # $6 = 短縮 抗原抗体 (どれかひとつ; 25字以内)
      # $7 = 細胞組織フル (パイプ 区切り)
      # $8 = 短縮 細胞組織 (どれかひとつ; 25字以内)
      # $9 = ChIP-Seq or DNase-Hypersensitivity
  }'
done


# ct_Statistics.$Genome.tab を作成。これをもとに Mac で分類作業をする。
for Type in ag ct; do # ct: cell type, ag: antigen
  TSV=$projectDir/classification/$Type"_"Statistics-$Genome-tab.tsv
  for fn in `ls $tagDir/*`; do
    cat $fn | awk -F '\t' -v TYPE=$Type '{
      if (TYPE == "ag") print $1 "\t" $2 "\t" $5  # $1=SRX, $2=SRA, $3=フル抗体名
      if (TYPE == "ct") print $1 "\t" $2 "\t" $7  # $1=SRX, $2=SRA, $3=フル細胞名
    }'
  done| tr ' ' '†'| sort -k2| sort -k3| uniq -c1| awk '{
    Cell[$4] = $4
    numSrx[$4] = numSrx[$4] + $1
    SRX[$4] = $2
    SRA[$4] = SRA[$4]$3
  } END {
    for (key in Cell) print gsub("RA", "", SRA[key]) "\t" numSrx[key] "\thttp://www.ncbi.nlm.nih.gov/sra?term=" SRX[key] "\t" Cell[key] "\t" Cell[key]
  }' | sort -nr -k1| sort -nr -k2| tr '†' ' '| awk '
  BEGIN {
    print "SRA\tSRX\tMGI\told\tnew"
  } {print}' | awk -F '\t' -v TSV=$TSV '
  BEGIN {
    while ((getline < TSV) > 0) arr[$4] = $5
  } {
    for (key in arr) if ($4 == key) $5 = arr[key]  # 旧 tsv と照合する。
    printf "%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5
  }' > $projectDir/classification/$Type"_"Statistics.$Genome.tab
                                    # $1 SRA の数, $2 SRX の数, $3 SRX の例, $4 細胞組織名, $5 細胞組織名
done


