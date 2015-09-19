#!/bin/sh
#$ -S /bin/sh

inBed=$1
Genome=$2
projectDir=$3

# inBed=chipome_test/results/sacCer3/public/all.05.ALL.al.bed
for SRX in `cut -f4 $inBed| sed 's/\]_\[/ /g'| tr -d '[]'| cut -d ' ' -f3| awk '!x[$1]++'`; do
  cat $projectDir/results/$Genome/tag/$SRX.tag.txt
done > $inBed.tmp

      # $1 = SRX
      # $2 = SRA
      # $3 = フルタイトル
      # $4 = 短縮タイトル
      # $5 = 抗原抗体
      # $6 = 短縮 抗原抗体
      # $7 = 細胞組織
      # $8 = 短縮 細胞組織
      # $9 = ChIP-Seq or DNase-Hypersensitivity

bn=`basename $inBed| sed 's/.bed//'`  # all.05.ALL.al
for listType in CL AG TT; do
  outHtml=`echo $inBed| sed s/.bed$/.$listType.html/`

  case $listType in
    CL)  cutF=7 ;;  # $7 = 細胞組織
    AG)  cutF=5 ;;  # $5 = 抗原抗体
    TT)  cutF=3 ;;  # $3 = フルタイトル
  esac

  cut -f $cutF $inBed.tmp| sort| uniq| awk -v GENOME=$Genome -v LISTTYPE=$listType -v BN=$bn '
    BEGIN {
      split(BN, arr, ".")
      if (arr[1] == "all") Type = "All data"
      if (arr[1] == "woH") Type = "ChIP-seq for TFs Pol2 and others"
      if (arr[1] == "His") Type = "ChIP-seq for Histones"
      if (arr[1] == "DHS") Type = "DNase-Hypersensitivity"
      
      qVal = arr[2]   # 例 05
      Attr = arr[3]   # 例 iPS_cells
      gsub("_", " ", Attr)
      
      if (arr[4] == "ct") CtAg = "Cell type and antigen filter: <B>Cell type = "
      if (arr[4] == "ag") CtAg = "Cell type and antigen filter: <B>Antigen = "
      if (arr[4] == "al") CtAg = "Cell type and antigen filter: <B>"
      
      if (LISTTYPE == "CL") LT = "List of cells and tissues: "
      if (LISTTYPE == "AG") LT = "List of antigens and antibodies: "
      if (LISTTYPE == "TT") LT = "List of titles: "
      
      print "Genome: <B>" GENOME "</B><BR>"   # Genome: hg19
      print "Data type: <B>" Type "</B><BR>"  # Data type: ChIP-seq for TFs Pol2 and others
      print "qVal <<B>1E-" qVal "</B><BR>"  # qVal < 1E-05
      print CtAg Attr "</B><BR><BR>"    # Cell and tissue filter: iPS cells
      print "<B>" LT "</B><BR>"               # List of cells and tissues: 
    } {
      gsub("_", " ", $1)
      print $1 "<BR>"
    }' > $outHtml
done
rm $inBed.tmp

