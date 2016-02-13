#!/bin/sh
#$ -S /bin/sh

# sh chipatlas/sh/dataNumbers.sh chipatlas

projectDir="$1"

# データ数の集計
tmpF1="tmpFile4ggplot_chipatlas1.txt"
tmpF2="tmpFile4ggplot_chipatlas2.txt"
tmpF3="tmpFile4ggplot_chipatlas3.txt"
tmpF4="tmpFile4ggplot_chipatlas4.txt"
allDataNumber="$projectDir/lib/assembled_list/allDataNumber.tsv" # 論文作成用

#                        ChIP_ENC  ChIP_Rodm DHS_ENC   DHS_Rodm
cat << DDD > "$tmpF1"
sacCer3  S.cerevisiae       0         0         0         0
ce10     C.elegans       1328         0         0         0
dm3      D.melanogaster  1026         0        12         0
mm9      M.musculus       414         0        73         0
hg19     H.sapiens       1992       967       342       248
DDD

cat $projectDir/lib/assembled_list/experimentList.tab| awk -v tmpF="$tmpF1" -v chipF="$tmpF3" -v dhsF="$tmpF4" -v allDataNumber="$allDataNumber" '
BEGIN {
  while ((getline < tmpF) > 0) {
    nr++
    for (j=1; j<=6; j++) x[nr, j] = $j
    y[nr] = x[nr, 1]
    sub("\\.", ". ", x[nr, 2])
  }
} {
  if ($3 == "DNase-seq") b[$2]++
  else                   a[$2]++
} END {
  print "Organism, Project, Numbers" > chipF
  print "Organism, Project, Numbers" > dhsF
  for (i=1; i<=nr; i++) {
    printf "%s, 1, %d\n", x[i, 2], x[i, 3]    >> chipF
    printf "%s, 2, %d\n", x[i, 2], x[i, 4]    >> chipF
    printf "%s, 3, %d\n", x[i, 2], a[x[i, 1]] >> chipF
    printf "%s, 1, %d\n", x[i, 2], x[i, 5]    >> dhsF
    printf "%s, 2, %d\n", x[i, 2], x[i, 6]    >> dhsF
    printf "%s, 3, %d\n", x[i, 2], b[x[i, 1]] >> dhsF
  }
  print "ChIP-seq\tENCODE\tRoadMap\tOthers" > allDataNumber
  for (i=nr; i>=1; i--) {
    printf "%s (%s)\t%d\t%d\t%d\n", x[i, 2], y[i], x[i, 3], x[i, 4], a[x[i, 1]] >> allDataNumber
  }
  print "DNase-seq\tENCODE\tRoadMap\tOthers" >> allDataNumber
  for (i=nr; i>=1; i--) {
    printf "%s (%s)\t%d\t%d\t%d\n", x[i, 2], y[i], x[i, 5], x[i, 6], b[x[i, 1]] >> allDataNumber
  }
}'


# 抗原、細胞クラスによる集計
cat $projectDir/lib/assembled_list/experimentList.tab| awk -F '\t' -v tmpF2=$tmpF2 -v chipF="$tmpF3" -v dhsF="$tmpF4" '
BEGIN {
  g["hg19"] = 1
  g["mm9"] = 2
  g["dm3"] = 3
  g["ce10"] = 4
  g["sacCer3"] = 5

  c["Adipocyte"] = 29
  c["Adult"] = 28
  c["Blood"] = 27
  c["Bone"] = 26
  c["Breast"] = 25
  c["Cardiovascular"] = 24
  c["Cell line"] = 23
  c["Digestive tract"] = 22
  c["Embryo"] = 21
  c["Embryonic fibroblast"] = 20
  c["Epidermis"] = 19
  c["Gonad"] = 18
  c["Kidney"] = 17
  c["Larvae"] = 16
  c["Liver"] = 15
  c["Lung"] = 14
  c["Muscle"] = 13
  c["Neural"] = 12
  c["Pancreas"] = 11
  c["Placenta"] = 10
  c["Pluripotent stem cell"] = 9
  c["Prostate"] = 8
  c["Pupae"] = 7
  c["Spleen"] = 6
  c["Uterus"] = 5
  c["Yeast strain"] = 4
  c["Others"] = 3
  c["Unclassified"] = 2
  c["No description"] = 1
  
  a["DNase-seq"] = 7
  a["Histone"] = 6
  a["RNA polymerase"] = 5
  a["TFs and others"] = 4
  a["Input control"] = 3
  a["Unclassified"] = 2
  a["No description"] = 1
  
  print "Organism, antigen, celltype" > tmpF2 # Documentation 用
} {
  printf "%s, %s, %s\n", g[$2], a[$3], c[$5] >> tmpF2 # Documentation 用
  A[$2,$3]++
  C[$2,$5]++
} END {
  for (genome in g) {
    for (antigen in a) printf "1\t%s\t%s\t%d\t%s\t%s\n", genome, antigen, A[genome, antigen], g[genome], a[antigen]
    for (celltyp in c) printf "2\t%s\t%s\t%d\t%s\t%s\n", genome, celltyp, C[genome, celltyp], g[genome], c[celltyp]
  }
}'| sort -t $'\t' -k1,1n -k5,5n -k6,6nr| cut -f 2-4 >> $allDataNumber





# R の実行
R-3.2.3/bin/Rscript $projectDir/sh/dataNumbers.R

rm "$tmpF1" "$tmpF2" "$tmpF3" "$tmpF4"

Date=`date +"%Y%m%d"`
mv "$projectDir/lib/assembled_list/allDataNumber.png" "$projectDir/lib/assembled_list/allDataNumber_"$Date".png"
mv "$projectDir/lib/assembled_list/antigenNumber.png" "$projectDir/lib/assembled_list/antigenNumber_"$Date".png"
mv "$projectDir/lib/assembled_list/cellTypeNumber.png" "$projectDir/lib/assembled_list/cellTypeNumber_"$Date".png"

cat << DDD
Markdown のリンク先変更

https://github.com/inutano/chip-atlas/wiki

[dataNumber]: http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/allDataNumber_$Date.png "Data numbers"
[antigenNumber]: http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/antigenNumber_$Date.png "Antigen classes"
[cellTypeNumber]: http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/cellTypeNumber_$Date.png "Cell type classes"

DDD

