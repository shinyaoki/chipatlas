#!/bin/sh
#$ -S /bin/sh

# qsub -o /dev/null -e /dev/null chipatlas/sh/dataAnalysis.sh chipatlas

projectDir=$1

sh $projectDir/sh/coLocalization.sh INITIAL $projectDir
sh $projectDir/sh/targetGenes.sh INITIAL $projectDir





for Genome in `ls $projectDir/results`; do
  ls $projectDir/results/$Genome/colo| grep ^"STRING_"| grep ".html"$| sed 's/STRING_//'| tr '.' '\t'| cut -f1-2| sort| uniq > tmpFileForColoList
  ls $projectDir/results/$Genome/targetGenes| grep ^"STRING_"| grep ".html"$| sed 's/STRING_//'| tr '.' '\t'| cut -f1| sort| uniq > tmpFileFortargetGenesList
    
  cat tmpFileForColoList tmpFileFortargetGenesList| cut -f1| sort| uniq| awk -F '\t' -v Genome=$Genome '
  BEGIN {
    while ((getline < "tmpFileForColoList") > 0)        gColo[$1] = gColo[$1] "," $2   # g["POU5F1"] = ,Epidermis,Pluripotent_stem_cell
    for (key in gColo) {
      sub(",", "", gColo[key])
      gsub("_", " ", gColo[key])
    }
    while ((getline < "tmpFileFortargetGenesList") > 0) gTarg[$1] = 1        # g["POU5F1"] = 1
  } {
    if (!gColo[$1]) gColo[$1] = "-"
    if (gTarg[$1] == 1) Targ = "+"
    else                Targ = "-"
    print $1 "\t" gColo[$1] "\t" Targ "\t" Genome
  }'
done > $projectDir/lib/assembled_list/analysisList.tab
rm tmpFileForColoList tmpFileFortargetGenesList

# $1 = 抗原小
# $2 = 細胞大 (Colo 用、コンマ区切り、ない場合は "-")
# $3 = Target gene の有無 ("+" or "-") hg19 ZNF3 は例外的にナシ。ピーク数が少なく、どの TSS の近くにもないためか。
# $4 = Genome
# ファイル名
# Colo : $1.gsub(" ", "_", $2).html
# Target : $1.html
