#!/bin/sh
#$ -S /bin/sh
# chipatlas/results/GENOME/tag/*.tag.txt ファイルを作成する
# 実行例 qsub chipatlas/sh/makeTag.sh chipatlas hg19

projectDir=$1
Genome=$2
cat $projectDir/results/$Genome/tag/*.tag.txt > $projectDir/results/$Genome/tag/tmp.tag.txt

cat $projectDir/results/$Genome/tag/tmp.tag.txt| awk -v ProjDir=$projectDir -v GENOME=$Genome -F '\t' '
BEGIN {
  agIndex = ProjDir"/classification/ag_Index."GENOME".tab"
  ctIndex = ProjDir"/classification/ct_Index."GENOME".tab"
  while ((getline var < agIndex) > 0) { # var = RNA Pol II|ab5408	Pol@ RNA polymerase II
    split(var, antg, "\t")              # antg[1] = RNA Pol II|ab5408 ; antg[2] = Pol@ RNA polymerase II
    sub(" ", "", antg[2])               # antg[1] = RNA Pol II|ab5408 ; antg[2] = Pol@RNA polymerase II
    gsub(" ", "_", antg[2])             # antg[1] = RNA Pol II|ab5408 ; antg[2] = Pol@RNA_polymerase_II
    UniAntg[antg[1]] = antg[2]          # UniAntg["RNA Pol II|ab5408"] = Pol@RNA_polymerase_II
  }
  while ((getline var < ctIndex) > 0) {
    split(var, cell, "\t")
    sub(" ", "", cell[2])
    gsub(" ", "_", cell[2])
    UniCell[cell[1]] = cell[2] # UniCell["hES_Cells"] = Embryonic_stem_cells
  }
} {                                                                       # $5 = RNA Pol II|ab5408
  UA = $6                                                                 # $6 = RNA Pol II (短縮抗原)
  UC = $8
  for (OriAntg in UniAntg) if ($5 == OriAntg) UA = UniAntg[OriAntg]       # OriAntg = RNA Pol II|ab5408 ; UA = Pol@RNA_polymerase_II
  for (OriCell in UniCell) if ($7 == OriCell) UC = UniCell[OriCell]
  print $0 "\t" UA "\t" UC > ProjDir"/results/"GENOME"/tag/"$1".tag.txt"
  # $1 = SRX
  # $2 = SRA
  # $3 = フルタイトル (GSM 除く)
  # $4 = 短縮タイトル (50 字以内)
  # $5 = 抗原抗体フル (パイプ 区切り)
  # $6 = 短縮 抗原抗体 (どれかひとつ; 25字以内)
  # $7 = 細胞組織フル (パイプ 区切り)
  # $8 = 短縮 細胞組織 (どれかひとつ; 25字以内)
  # $9 = ChIP-Seq or DNase-Hypersensitivity
  # $10= 統一された抗原名 (Pol@RNA_polymerase_II) または 25 字以内のオリジナル抗原名 (Unc の場合は $6)
  # $11= 統一された細胞名 (PSC@Embryobic_stem_cells) または 25 字以内のオリジナル細胞名 (Unc の場合は $8)
  close (ProjDir"/results/"GENOME"/tag/"$1".tag.txt")
}'
rm $projectDir/results/$Genome/tag/tmp.tag.txt
