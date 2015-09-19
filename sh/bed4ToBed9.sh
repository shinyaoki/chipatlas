#!/bin/sh
#$ -S /bin/sh
# BED4 ファイルを BED9 形式にする
# 実行例 sh $projectDir/sh/bed4ToBed9.sh


RR=0
ctn=0
Type=0
while getopts r: option
do
  case "$option" in
  r)
    Type="$OPTARG"
    ;;
  esac
done

# オプション解析終了後に不要となったオプション部分を shift コマンドで切り捨てる
shift `expr $OPTIND - 1`

####################################################################################################################################
#                                                             初期モード
####################################################################################################################################
if [ $Type = "0" ]; then
  projectDir=`echo $0| sed 's[/sh/bed4ToBed9.sh[['`
  QSUB="sh $projectDir/sh/QSUB.sh"
  GENOME=`ls $projectDir/results/| tr '\n' ' '`
  QVAL=$(ls $projectDir/results/`ls $projectDir/results/| head -n1`| grep Bed| cut -c 4-| tr '\n' ' ')
  rm -rf $projectDir/tmpDirForSort
  mkdir $projectDir/tmpDirForSort

  # tsv ファイルを整形
  # xhipome_ver3/classification/ag_Statistics-hg19-tab.tsv
  # 5	108	http://www.ncbi.nlm.nih.gov/sra?term=SRX669610	H3K4me3|07-473	His@ H3K4me3
  for TSV in `ls $projectDir/classification/*Statistics-*-tab.tsv`; do
    outIndex=`echo $TSV| sed 's/Statistics-/Index./'| sed 's/-tab.tsv/.tab/'`
    tail -n +2 $TSV| sed 's/?[0-9]//g'| awk -F '\t' '{if($4 != $5) print $4 "\t" $5}' > $outIndex
    # xhipome_ver3/classification/ag_Index.hg19.tab
    # input|NA	InP@ Input
    # H3K9me3|AB8898	His@ H3K9me3
    # anti-H3 (Abcam 1791)	His@ H3
  done

# 統一された細胞・抗原名を $projectDir/results/$Genome/tag/*.tag.txt に追加する
  echo 統一された細胞・抗原名を追加中...
  for Genome in `echo $GENOME`; do
    echo $Genome...
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
  done


  for Genome in `echo $GENOME`; do
    rm -rf $projectDir/results/$Genome/[DES]RX[0-9]*
    rm -rf $projectDir/results/$Genome/log/bed4ToBed9
    rm -rf $projectDir/results/$Genome/public
    mkdir $projectDir/results/$Genome/log/bed4ToBed9
    mkdir $projectDir/results/$Genome/public
    for qVal in `echo $QVAL`; do
      for agType in `cat $projectDir/sh/abbreviationList_AG.tab| cut -f1`; do
                  # 全て, ヒストンのみ, Inputのみ, Pol2のみ, DNaseのみ, その他 (TFs), 記述なし, 分類不能
        Logfile=$projectDir/results/$Genome/log/bed4ToBed9/$agType.$qVal.log.txt
        # 不要: nSlot=`du -sm $projectDir/results/$Genome/Bed$qVal/Bed/| awk '{printf "%d", int($1/950)+1}'`
        $QSUB -o $Logfile -e $Logfile $projectDir/sh/bed4ToBed9.sh -r $agType $qVal $Genome $projectDir
      # qsub                         -pe def_slot 4     chipome_ver3/sh/bed4ToBed9.sh -r His       05    mm9     chipome_ver3
      done
    done
  done
  LogFile=classify.log.txt
  rm -rf $LogFile
  qsub -o $LogFile -e $LogFile $projectDir/sh/classify.sh $projectDir
  exit
fi


####################################################################################################################################
#                                                             以下、qsub モード
####################################################################################################################################

qVal=$1        # (例) 05
Genome=$2      # (例) mm9
projectDir=$3  # (例) chipome_ver3
# qsub -pe def_slot 4 chipome_ver3/sh/bed4ToBed9.sh -r His 05 mm9 chipome_ver3
tmpDir=$projectDir/tmpDirForSort/$JOB_ID
mkdir $tmpDir
QLARGE=`cat $projectDir/sh/preferences.txt |awk -F '\t' '{if ($1 == "qLarge") printf "%s", $2}'` # 1E-50, 1E-75, 1E-99 などを MACS2 によらずに作る。
dirIn=$projectDir/results/$Genome/Bed$qVal/Bed                   # Bed4 ファイルが入っているディレクトリ (例) chipome_ver3/results/mm9/Bed05/Bed
bnOut=$projectDir/results/$Genome/public/$Type.ALL.$qVal.AllAg.AllCell      # 出力のディレクトリ+basename
# (例) chipome_ver3/results/mm9/public/His.ALL.05.AllAg.AllCell とすると His.05.AllAg.AllCell.bed などができる

# Type ごとに分類
cat $projectDir/results/$Genome/tag/*.tag.txt| tr ' ' '_'| awk -F '\t' -v TYPE=$Type '{
  delete antg
  delete cell
  if (substr($11, 4, 1) == "@") {  # @ 以降を細胞組織名にする
    split($11, cell, "@")
    $11 = cell[2] "_@" cell[1]
  }
  split($10, antg, "@")
  $10 = antg[2]

  if (TYPE == "ALL") {   # ALL
    print
  }
  else if (antg[1] == TYPE) {   # His InP Pol DNS Oth NoD Unc
    print
  }

# タグの決定
}'| tr ' ' '\t'| awk -F '\t' '{
  if (substr($1, length($1)-3, 1) == "@") $11 = substr($11, 5, 100)
  printf "%s\t[%s]_[%s]_[%s]\n", $1, $10, $11, $1         # SRX  [抗原抗体]_[細胞組織]_[SRX]

# カラーコードの付加
}'| awk -v Prj=$projectDir -v GENOME=$Genome -v QVAL=$qVal -v tmpDir=$tmpDir '
BEGIN {
  MAX=1000
  N=MAX/4
  b=255
} {
  TAG = $2
  inBed = Prj"/results/"GENOME"/Bed"QVAL"/Bed/"$1"."QVAL".bed"
  while ((getline < inBed) > 0) {
    x=$5
    if(x<N) {
      R=0
      G=b/N*x
      B=b
    }
    else if (x>=N && x<2*N) {
      R=0
      G=b
      B=-b/N*x+2*b
    }
    else if (x>=2*N && x<3*N) {
      R=b/N*x-2*b
      G=b
      B=0
    }
    else if (x>=3*N && x<4*N) {
      R=255
      G=-b/N*x+4*b
      B=0
    }
    else if (x>=4*N) {
      R=255
      G=0
      B=0
    }
    COL=int(R)","int(G)","int(B)

    if ($5 > 1000) pVal=1000
    else pVal=int($5)

    printf "%s\t%s\t%s\t%s\t%s\t.\t%s\t%s\t%s\n", $1, $2, $3, TAG, pVal, $2, $3, COL > tmpDir "/" $1
  }
  close(inBed)
}'

for chr in `ls $tmpDir| sort -k1,1`; do
  sort -k2,2n $tmpDir/$chr >> $bnOut.bed
done
rm -r $tmpDir

# QVAL="05 10 20" の場合、qVal=20 のとき QLARGE="50 75 99" のBigBed を閾値で作る。
LargestQval=`ls $projectDir/results/*/| grep Bed| cut -c 4-|sort -n|tail -n1`
if [ $qVal = "$LargestQval" ]; then
  for qLarge in `echo $QLARGE`; do
    largeBnOut=$projectDir/results/$Genome/public/$Type.ALL.$qLarge.AllAg.AllCell
    cat $bnOut.bed| awk -v threshold=$qLarge '{if ($5 > threshold*10) print}' > $largeBnOut.bed
  done
fi

rm $bnOut.unsrt.bed
