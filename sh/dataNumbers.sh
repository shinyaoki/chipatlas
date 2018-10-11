#!/bin/sh
#$ -S /bin/sh

# sh chipatlas/sh/dataNumbers.sh chipatlas

# ENCODE データの取得法
cat << DDD > /dev/null
(1) GEO DataSets の Advanced Search で Project を絞り込み検索
  ENCODE:  "encode" OR "modencode" OR "mouse encode" OR "pilot encode"
  Roadmap: "roadmap epigenomics"
(2) 右上の Database: を "SRA" に選択
(3) Send to: File > Format = "summary" でダウンロード
(4) ファイル名を以下のように変更
  sra_result_Roadmap.csv
  sra_result_ENCODE.csv
(5) スパコンの以下のフォルダに転送
  chipatlas/lib/ENCODE_RoadMap
DDD


# ここから本番
projectDir="$1"
expList="$projectDir/lib/assembled_list/experimentList.tab"
allDataNumber="$projectDir/lib/assembled_list/allDataNumber.tsv" # 論文作成用
tmpF1="tmpFile4ggplot_chipatlas1.txt" # allDataNumber 用
tmpF2="tmpFile4ggplot_chipatlas2.txt" # 描画用 (クラス分け)
tmpF3="tmpFile4ggplot_chipatlas3.txt" # 描画用 (ChIP)
tmpF4="tmpFile4ggplot_chipatlas4.txt" # 描画用 (DHS)
echo "Document のグラフを更新中..."

# ENOCODE と RoadMap のデータ数をカウント
{
  cat $projectDir/lib/ENCODE_RoadMap/sra_result_ENCODE.csv| awk -F '=' '$0 ~ /^SRA Run Selector:/ {
    print $2
  }'| tr ',' '\n'| grep [DES]RX| awk '!a[$1]++ {print $1 "\tENCODE"}'
  cat $projectDir/lib/ENCODE_RoadMap/sra_result_Roadmap.csv| awk -F '=' '$0 ~ /^SRA Run Selector:/ {
    print $2
  }'| tr ',' '\n'| grep [DES]RX| awk '!a[$1]++ {print $1 "\tRoadMap"}'
    
}| awk -F '\t' -v expList="$expList" '
BEGIN {
  while ((getline < expList) > 0) {
    s[$1]++
    g[$1] = $2
    p[$1] = "Others"
    if ($3 == "DNase-seq") A[$1] = "DNase-seq"
    else                   A[$1] = "ChIP-seq"
  }
} {
  if (s[$1] > 0) p[$1] = $2
} END {
  Np = split("ENCODE RoadMap Others", P, " ")
  Nx = split("hg19 mm9 rn6 dm3 ce10 sacCer3", x, " ")
  Ny = split("H. sapiens (hg19)|M. musculus (mm9)|R. norvegicus (rn6)|D. melanogaster (dm3)|C. elegans (ce10)|S. cerevisiae (sacCer3)", y, "|")
  Ne = split("ChIP-seq DNase-seq", e, " ")
  
  for (srx in g) n[A[srx], g[srx], p[srx]]++
  
  for (m=1; m<=Ne; m++) {
    printf e[m]
    for (j=1; j<=Np; j++) printf "\t" P[j]
    printf "\n"
    for (i=1; i<=Nx; i++) {
      printf y[i]
      for (j=1; j<=Np; j++) printf "\t%d", n[e[m], x[i], P[j]]
      printf "\n"
    }
  }
}' > "$tmpF1"


# 描画用の tmp ファイル作成 (全データ数)
cat "$tmpF1"| sed 's/ (/@/'| tr '@' '\t'| awk -F '\t' '{
  if ($0 ~ "Others") {
    Exp = $1
    k++
    f[Exp] = "tmpFile4ggplot_chipatlas" k+2 ".txt"
  } else {
    for (i=3; i<=5; i++) x[Exp, $1, i-2] = $i
  }
} END {
  Ng = split("S. cerevisiae|C. elegans|D. melanogaster|R. norvegicus|M. musculus|H. sapiens", g, "|")
  for (Exp in f) {
    print "Organism, Project, Numbers" > f[Exp]
    for (i=1; i<=Ng; i++) for (j=1; j<=3; j++) print g[i] ", " j ", " x[Exp, g[i], j] >> f[Exp]
  }
}'


# 全データ数 (論文作成用)
cat "$tmpF1" > "$allDataNumber"


# 抗原や細胞クラスのカウント (論文作成用)
cat "$expList"| awk -F '\t' '{
  x[$2, $3]++
  y[$2, $5]++
} END {
  Ng = split("hg19|mm9|rn6|dm3|ce10|sacCer3", g, "|")
  Na = split("DNase-seq|Histone|RNA polymerase|TFs and others|Input control|Unclassified|No description", a, "|")
  Nc = split("Adipocyte|Adult|Blood|Bone|Breast|Cardiovascular|Cell line|Digestive tract|Embryo|Embryonic fibroblast|Epidermis|Gonad|Kidney|Larvae|Liver|Lung|Muscle|Neural|Pancreas|Placenta|Pluripotent stem cell|Prostate|Pupae|Spleen|Uterus|Yeast strain|Others|Unclassified|No description", c, "|")
  for (i=1; i<=Ng; i++) for (j=1; j<=Na; j++) printf "%s\t%s\t%d\n", g[i], a[j], x[g[i], a[j]]
  for (i=1; i<=Ng; i++) for (j=1; j<=Nc; j++) printf "%s\t%s\t%d\n", g[i], c[j], y[g[i], c[j]]
}'| sed 's/Embryonic fibroblast/Emb fibroblast/g'| sed 's/Pluripotent stem cell/Pluripotent SC/g' >> "$allDataNumber"


# 抗原、細胞クラスによる集計
cat "$expList"| awk -F '\t' '
BEGIN {
  Ng = split("hg19|mm9|rn6|dm3|ce10|sacCer3", g, "|")
  Nc = split("No description|Unclassified|Others|Yeast strain|Uterus|Spleen|Pupae|Prostate|Pluripotent stem cell|Placenta|Pancreas|Neural|Muscle|Lung|Liver|Larvae|Kidney|Gonad|Epidermis|Embryonic fibroblast|Embryo|Digestive tract|Cell line|Cardiovascular|Breast|Bone|Blood|Adult|Adipocyte", c, "|")
  Na = split("No description|Unclassified|Input control|TFs and others|RNA polymerase|Histone|DNase-seq", a, "|")
  for (i=1; i<=Ng; i++) G[g[i]] = i
  for (i=1; i<=Nc; i++) C[c[i]] = i
  for (i=1; i<=Na; i++) A[a[i]] = i
  print "Organism, antigen, celltype"
} {
  printf "%d, %d, %d\n", G[$2], A[$3], C[$5]
}' > "$tmpF2"


# R の実行
R-3.2.3/bin/Rscript $projectDir/sh/dataNumbers.R

rm "$tmpF1" "$tmpF2" "$tmpF3" "$tmpF4"

Date=`date +"%Y%m%d"`
mv "$projectDir/lib/assembled_list/allDataNumber.png" "$projectDir/lib/assembled_list/allDataNumber_"$Date".png"
mv "$projectDir/lib/assembled_list/antigenNumber.png" "$projectDir/lib/assembled_list/antigenNumber_"$Date".png"
mv "$projectDir/lib/assembled_list/cellTypeNumber.png" "$projectDir/lib/assembled_list/cellTypeNumber_"$Date".png"


# リンク先変更の通知
echo $'\e[41m''Document のグラフが更新されました。'$'\e[m'
echo $'\e[41m''ラボの Mac で以下のコマンドを実行し、Markdown のリンク先を変更してください。'$'\e[m'
cat << DDD

cat /Users/Oki/Desktop/沖　真弥/実験/chipAtlas/スクリプト/chipatlas_git/documents.md| sed "s/Number_20[0-9][0-9][0-9][0-9][0-9][0-9]/Number_$Date/" > /tmp/tmpNumber_$Date
mv  /tmp/tmpNumber_$Date /Users/Oki/Desktop/沖　真弥/実験/chipAtlas/スクリプト/chipatlas_git/documents.md

終わったら、y + Enter を押してください。
引き続き、Colo, TargetGene, in silico ChIP 用のファイル転送, in silico ChIP を行います。
DDD

while read line; do
  if [ "$line" = "y" ]; then
    break
  fi
done
