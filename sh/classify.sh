#!/bin/sh
#$ -S /bin/sh

Mode=initial
while getopts m: option
do
  case "$option" in
  m)
    Mode="$OPTARG" # qsub モード (Mode=x Cross モード;  Mode=m multiple mode)
    ;;
  esac
done

# オプション解析終了後に不要となったオプション部分を shift コマンドで切り捨てる
shift `expr $OPTIND - 1`

projectDir=$1
QSUB="sh $projectDir/sh/QSUB.sh"
declare -A BEDFILE                # -Aでハッシュ宣言 
GENOME=`ls $projectDir/results/| tr '\n' ' '`


if [ $Mode = "initial" ]; then
  rm -f $projectDir/classification/*.tmpIndexForFgrep

  while :; do
    qstatN=`qstat| awk '{if ($3 == "bed4ToBed9") print}'| wc -l`
    if [ $qstatN -eq 0 ]; then
      break
    fi
  done
  rm -r $projectDir/tmpDirForSort
  
  # 抗原大分類と細胞大分類を掛け合わせる
  for Genome in `echo $GENOME`; do
    ql=`sh $projectDir/sh/QSUB.sh mem`
    for bedFile in `ls -l $projectDir/results/$Genome/public/*bed| awk '{if ($5 > 0) printf "%s ", $10}'`; do
      # bedFile = xhipome_ver3/results/hg19/public/InP.ALL.60.AllAg.AllCell.bed
      for LargeCellType in `cut -f2 $projectDir/classification/ct_Index.$Genome.tab| cut -c1-3|sort|uniq`; do
        qsub $ql -o /dev/null -e /dev/null $projectDir/sh/classify.sh -m x $projectDir "$LargeCellType" $bedFile $Genome
                                                                                  #  LargeCellType = PSC Lng ALL Unc など
      done
    done
  done

  while :; do
    qstatN=`qstat| awk '{if ($3 == "classify.s") print}'| wc -l`
    if [ $qstatN -eq 1 ]; then
      break
    fi
  done

  # 抗原小分類と細胞小分類をつける
  for Index in `ls $projectDir/classification/*Index*.tab`; do
    ctORag=`basename $Index| cut -d '_' -f1`    # 例 ct または ag
    Genome=`basename $Index| cut -d '.' -f2`    # 例 hg19
    indexForFgrep=`cut -f2 $Index| sort| uniq| tr '\n ' ' _'` # PSC@_Embryonic_stem_cells など
        
    ls $projectDir/results/$Genome/public/*bed| awk -F '/' '{print $NF}'| tr '.' '\t'| awk -F '\t' -v ctORag="$ctORag" -v indexForFgrep="$indexForFgrep" -v projectDir="$projectDir" -v Genome=$Genome '
    BEGIN {
      N = split(indexForFgrep, a, " ")
      for (i=1; i<=N; i++) {
        LargeType = substr(a[i], 1, 3)     # PSC など
        SmallType = substr(a[i], 6, 3000)  # Embryonic_stem_cells など
        n[LargeType]++
        x[LargeType, n[LargeType]] = SmallType  # x[PSC, 3] = Embryonic_stem_cells
      }
    } {
      LargeAg = $1 # His Oth など
      LargeCt = $2 # ALL PSC など
      bedFile = projectDir "/results/" Genome "/public/" $1 "." $2 "." $3 "." $4 "." $5 "." $6
      if (ctORag == "ag") {
        for (i=1; i<=n[LargeAg]; i++) {
          print "sh " projectDir "/sh/classify.sh -m m " LargeAg " \"" x[LargeAg, i] "\" "ctORag " " bedFile
        }
      } else if (ctORag == "ct") {
        for (i=1; i<=n[LargeCt]; i++) {
          print "sh " projectDir "/sh/classify.sh -m m " LargeCt " \"" x[LargeCt, i] "\" "ctORag " " bedFile
        }
      }
    }'
  done| awk '{print rand() "\t" $0}'| sort -n| cut -f2- > $projectDir/classify.tmp
  
  ql=`sh $projectDir/sh/QSUB.sh mem`
  splitN=`cat $projectDir/classify.tmp| wc -l| awk '{print int($1/500)}'`
  split -l $splitN $projectDir/classify.tmp CLASSIFY_TMP
  for tmpList in `ls CLASSIFY_TMP*`; do
    cat $tmpList| qsub $ql -N classify.sh -o /dev/null -e /dev/null
  done

  # classify.sh が全て終わったら、makeBigBed 投入
  while :; do
    qstatN=`qstat| awk '{if ($3 == "classify.s") print}'| wc -l`
    if [ $qstatN -eq 1 ]; then
      rm -f $projectDir/classification/*.tmpIndexForFgrep
      rm CLASSIFY_TMP* $projectDir/classify.tmp
      qsub -pe def_slot 4 -o /dev/null -e /dev/null $projectDir/sh/makeBigBed.sh -i $projectDir
      exit
    fi
  done
fi


####################################################################################################################################
#                                                             以下、qsub モード
####################################################################################################################################


###################################################################
# qsub モード (Mode=x Cross モード) 抗原大分類と細胞大分類を掛け合わせる
###################################################################
if [ $Mode = "x" ]; then
# qsub -o /dev/null -e /dev/null $projectDir/sh/classify.sh -m x $projectDir "$LargeCellType" $bedFile $Genome
  projectDir=$1
  LargeCellType="$2"  # (Mode=x PSC Lng など)
  bedFile=$3  # xhipome_ver3/results/hg19/public/InP.ALL.60.AllAg.AllCell.bed
  Genome=$4
  ctORag=$5
  bn=`echo $bedFile| sed 's/.AllAg.AllCell.bed$//'`  # xhipome_ver3/results/hg19/public/InP.ALL.60 など
  outFn=`echo $bedFile| sed "s/\.ALL\./\.$LargeCellType\./"`  # xhipome_ver3/results/hg19/public/InP.PSC.60.AllAg.AllCell.bed
  
  cut -f2 $projectDir/classification/ct_Index.$Genome.tab| fgrep "$LargeCellType@ "|sort|uniq| tr ' ' '_'| awk '{
    printf "_[%s_@%s]_\n", substr($1, 6, 100), substr($1, 1, 3)
  }' > $bn.$LargeCellType.tmp
  fgrep -f $bn.$LargeCellType.tmp $bedFile > $outFn
  rm $bn.$LargeCellType.tmp
fi


###################################################################
# qsub モード (Mode=m multiple モード) 抗原小分類と細胞小分類をつける
###################################################################
if [ $Mode = "m" ]; then
# qsub -o /dev/null -e /dev/null $projectDir/sh/classify.sh -m m $LargeType $SmallType $ctORag $bedFile
  LargeType=$1 # PSC など
  SmallType="$2" # Embryonic_stem_cells など
  smalltype=`echo $SmallType| sed 's/(/BRACKETL/g'| sed 's/)/BRACKETR/g'| sed 's/\./PERIOD/g'| sed 's[/[SLASH[g'` # カッコとピリオドとスラッシュを変換
  ctORag=$3    # ct または ag  
  bedFile=$4   # xhipome_ver3/results/hg19/public/Oth.PSC.60.AllAg.AllCell.bed
  
  if [ $ctORag = "ag" ]; then
    outFn=`echo $bedFile| sed "s/AllAg/$smalltype/"`
    fgrep "["$SmallType"]_" $bedFile > $outFn
  elif [ $ctORag = "ct" ]; then
    outFn=`echo $bedFile| sed "s/AllCell/$smalltype/"`
    fgrep "["$SmallType"_@"$LargeType"]_" $bedFile > $outFn
  fi
fi
