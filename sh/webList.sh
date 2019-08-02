#!/bin/sh
#$ -S /bin/sh

# qsub chipatlas/sh/webList.sh chipatlas                # makeBigBed.sh の最後に実行

projectDir=$1
minQval=`cat $projectDir/sh/preferences.txt | awk '$1 ~ "qVal" {printf "%s", $2}'`

# ATCC, Yun etal などをまとめる
for fn in `ls $projectDir/sh/cellTypeDescription/*.tab`; do
  cat $fn| tr -d '=|'| awk -F '\t' -v fn=$fn '{
    if (fn ~ "atccCollection.tab") {
      printf "2\t%s", $2
      if ($6) printf "\tTissue=%s", $6
      if ($4) printf "\tCell Type=%s", $4
      if ($5) printf "\tDisease=%s", $5
      printf "\n"
    }
    if (fn ~ "ENCODE.tab") {
      printf "4\t%s", $1
      if ($6) printf "\tTissue=%s", $6
      if ($5) printf "\tLineage=%s", $5
      if ($4) printf "\tDescription=%s", $4
      printf "\n"
    }
    if (fn ~ "FlyBaseCollection.tab") {
      printf "5\t%s", $1
      if ($3 && $3 != "-") printf "\tSource=%s", $3
      if ($4 && $4 != "-") printf "\tTissue Source=%s", $4
      if ($5 && $5 != "-") printf "\tDevelopmental Stage=%s", $5
      printf "\n"
    }
    if (fn ~ "mesh") {
      printf "3\t%s", $2
      if ($3) printf "\tMeSH Description=%s", $3
      printf "\n"
    }
    if (fn ~ "Yu_etal.tab") {
      printf "1\t%s", $1
      if ($4) printf "\tPrimary Tissue=%s", $4
      if ($5) printf "\tSite of Extraction=%s", $5
      if ($6) printf "\tTissue Diagnosis=%s", $6
      printf "\n"
    }
  }'
done| awk -F '\t' '{
  printf "%s\t%s\t", $1, $2
  if (NF == 2) print "-"
  else {
    Desc = ""
    for (i=3; i<=NF; i++) Desc = Desc "|" $i
    sub ("\\|", "", Desc)
    print Desc
  }
}' > $projectDir/sh/cellTypeDescription/cellTypeDescription.txt
      # 1       K-562   Primary Tissue=Blood|Tissue Diagnosis=Leukemia Chronic Myelogenous

rm -f "alignmentPercentage.tab"
for Genome in `ls $projectDir/results/| tr '\n' ' '`; do
  echo $projectDir/results/$Genome/log/*.log.txt| xargs cat| awk -v minQval=$minQval '{
    if ($0 ~ "Job ID = ") x = ""
    if ($0 ~ "overall alignment rate") x = $1
    if ($0 ~ "Command line: callpeak" && $0 ~ "-q 1e-" minQval) printf "%s\t%f\n", $6 , x
  }'| tr -d '%'| sed 's/.bam//'| awk -F '/' '{print $NF}' >> alignmentPercentage.tab
done

# experimentlist.tab の作成
for Genome in `ls $projectDir/results/| tr '\n' ' '`; do
  rm -f $projectDir/results/$Genome/summary/all*.txt
  echo $projectDir/results/$Genome/summary/*RX*.txt| xargs cat > $projectDir/results/$Genome/summary/allSummary.txt
  cd $projectDir/results/$Genome/Bed$minQval/Bed/
  echo *.bed| xargs wc -l| sed "s/\.$minQval\.bed//"| awk '{print $2 "\t" $1}' > ~/$projectDir/results/$Genome/summary/allLineNum.txt
  cd
  
  echo $projectDir/results/$Genome/tag/*.tag.txt| xargs cat| awk -F '\t' -v Genome=$Genome -v PROJD=$projectDir -v minQval=$minQval '
  BEGIN {
    agList=PROJD "/sh/abbreviationList_AG.tab"
    ctList=PROJD "/sh/abbreviationList_CT.tab"
    Summary=PROJD "/results/" Genome "/summary/allSummary.txt"
    LineNum=PROJD "/results/" Genome "/summary/allLineNum.txt"
    ctStTSV=PROJD "/classification/ct_Statistics-" Genome "-tab.tsv"
    ctDescr=PROJD "/sh/cellTypeDescription/cellTypeDescription.txt"
    
    while ((getline < agList) > 0) AG[$1] = $2
    close(agList)
    while ((getline < ctList) > 0) CT[$1] = $2
    close(ctList)
    while ((getline < LineNum) > 0) lNum[$1] = $2 # Bed05 の行数
    close(LineNum)
    while ((getline < "alignmentPercentage.tab") > 0) map[$1] = $2 # Mappability
    close("alignmentPercentage.tab")
    while ((getline < Summary) > 0) {
      readInfo[$1] = sprintf("%d,%.1f,%.1f,%d", $5, map[$1], $8, lNum[$1]) # Nspots, Mappability, dupPercent, Bed05_NR
    }
    close(Summary)
    while ((getline < ctDescr) > 0) ctD[$1,$2] = $3   # ctD["1","K-562"] = Primary Tissue=Blood|Tissue Diagnosis=Leukemia Chronic Myelogenous
    close(ctDescr)
    while ((getline < ctStTSV) > 0) {   # $5  = PSC@ Embryonic Stem Cells?3
      sub(" ", "", $5)                  # $5  = PSC@Embryonic Stem Cells?3
      split($5, c, "?")                 # c[1] = PSC@Embryonic Stem Cells, c[2] = 3
      split(c[1], f, "@")               # f[2] = Embryonic Stem Cells
      ctDesc[f[2]] = ctD[c[2],f[2]]     # ctDesc["Embryonic Stem Cells"] = Primary Tissue=Blood|Tissue Diagnosis=Leukemia Chronic Myelogenous
    }
    close(ctStTSV)
  } {
    SRX = $1
    meta = PROJD "/results/" Genome "/metadata/" SRX ".meta.txt"
    gsub("_", " ", $10)
    gsub("_", " ", $11)
    
    if (substr($10, 4, 1) == "@") {   # Unc 以外
      agL = AG[substr($10, 1, 3)]
      agS = substr($10, 5, 300)
    } else {                          # Unc の場合、agL = "Unclassified"; agS = 自動抽出
      agL = AG["Unc"]
      agS = $10
    }
      
    if (substr($11, 4, 1) == "@") {   # Unc 以外
      ctL = CT[substr($11, 1, 3)]
      ctS = substr($11, 5, 300)
    } else {                          # Unc の場合、ctL = "Unclassified"; ctS = 自動抽出
      ctL = CT["Unc"]
      ctS = $11
    }
    
    if (ctDesc[ctS]) Dscrp = ctDesc[ctS]
    else             Dscrp = "NA"
    
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t", SRX, Genome, agL, agS, ctL, ctS, Dscrp, readInfo[SRX]
    while ((getline var < meta) > 0) {
      nf = split(var, arr, "\t")
      gsub("_", " ", arr[3])    # arr[3] = フルタイトル (GSM 含む)
      if (arr[3] == "xxx") arr[3] = "-"
      printf "%s", arr[3]
      for (i=18; i<=nf; i++) printf "\t%s", arr[i]
    }
    printf "\n"
  }'
done > $projectDir/lib/assembled_list/experimentList.tab
# $1 = SRX                          SRX377114
# $2 = Genome                       sacCer3
# $3 = 抗原 大                       Histone
# $4 = 抗原 小 (Unc の場合は自動抽出)   H3K36me3
# $5 = 細胞 大                       Yeast strain
# $6 = 細胞 小 (Unc の場合は自動抽出)   ZKY329
# $7 = 細胞小の記述 (ない場合は NA)     Primary Tissue=Blood|Tissue Diagnosis=Leukemia Chronic Myelogenous
# $8 = リード情報                     Nspots, Mappability, dupPercent, Bed05_NR
# $9 = フルタイトル (GSM 含む)         GSM1263467: H3K36me3 ChIP-seq t1; Saccharomyces cerevisiae; ChIP-Seq
# $10 以降 : メタデータ (タブ区切り)     source_name=YMC cycling cells	strain=ZKY329	chip antibody=H3K36me3 [ab9050 (Abcam)]
rm $projectDir/results/$Genome/summary/all*.txt alignmentPercentage.tab


# WEB 検索用 HTML の作成
sh chipatlas/sh/refineSearchList.sh


# filelist.tab の作成
for genome in `ls $projectDir/results/`; do
  echo $projectDir/results/$genome/public/*.list| xargs cat
  echo $projectDir/results/$genome/public/*.list| xargs rm
done > $projectDir/lib/assembled_list/fileList.tab
# $1 = ファイル名                     His.Lar.10.H3K4me3.AllCell.bed
# $2 = Genome                       ce10
# $3 = 抗原 大                       Histone
# $4 = 抗原 小 (AllAg の場合は -)     H3K4me3
# $5 = 細胞 大                       Larvae
# $6 = 細胞 小 (AllCell の場合は -)   -
# $7 = q-Val                        10
# $8 = SRX (コンマ区切り)             SRX059255,SRX063957,SRX059274,SRX059273,SRX059254


# Antigen, CellType リスト の作成
cat $projectDir/lib/assembled_list/experimentList.tab| sort| awk -F '\t' -v projectDir=$projectDir '
BEGIN {
  print "Genome\tAntigen_class\tAntigen\tNum_data\tID" > projectDir"/lib/assembled_list/antigenList.tab"
  print "Genome\tCell_type_class\tCell_type\tNum_data\tID" > projectDir"/lib/assembled_list/celltypeList.tab"
  cmd = "sort"
} {
  a[$2 "\t" $3 "\t" $4]++
  c[$2 "\t" $5 "\t" $6]++
  srxA[$2 "\t" $3 "\t" $4] = srxA[$2 "\t" $3 "\t" $4] "," $1
  srxC[$2 "\t" $5 "\t" $6] = srxC[$2 "\t" $5 "\t" $6] "," $1
} END {
  for (key in a) {
    sub(",", "", srxA[key])
    print key "\t" a[key] "\t" srxA[key] |& cmd
  }
  close(cmd, "to")
  while((cmd |& getline var) > 0) print var >> projectDir"/lib/assembled_list/antigenList.tab"
  close(cmd)
  
  for (key in c) {
    sub(",", "", srxC[key])
    print key "\t" c[key] "\t" srxC[key] |& cmd
  }
  close(cmd, "to")
  while((cmd |& getline var) > 0) print var >> projectDir"/lib/assembled_list/celltypeList.tab"
  close(cmd)
}'
