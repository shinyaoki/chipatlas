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
  for Genome in `echo $GENOME`; do
    BEDFILE["$Genome"]=`ls $projectDir/results/$Genome/public/*bed| tr '\n' ' '`
  done
  
  for Index in `ls $projectDir/classification/*Index*.tab`; do
    ql=`sh $projectDir/sh/QSUB.sh mem`
    echo $Index >> classify.log.txt
    ctORag=`basename $Index| cut -d '_' -f1`    # 例 ct または ag
    Genome=`basename $Index| cut -d '.' -f2`    # 例 hg19
    indexForFgrep=`cut -f2 $Index| sort| uniq| tr '\n ' ' _'` # PSC@_Embryonic_stem_cells など

    for idx in `echo $indexForFgrep`; do # 例: idx = PSC@_Embryonic_stem_cells など
      LargeType=`echo $idx| cut -c1-3` # PSC など
      SmallType=`echo $idx| cut -c6-`  # Embryonic_stem_cells など
      
      for bedFile in `echo ${BEDFILE[$Genome]}`; do # xhipome_ver3/results/hg19/public/His.ALL.50.AllAg.AllCell.bed など
        LargeAg=`basename $bedFile| cut -d '.' -f1` # His Oth など
        LargeCt=`basename $bedFile| cut -d '.' -f2` # ALL PSC など
        if [ "$ctORag" = "ct" ]; then
          if [ "$LargeType" != "$LargeCt" ]; then
            continue
          fi
        elif [ "$ctORag" = "ag" ]; then
          if [ "$LargeType" != "$LargeAg" ]; then
            continue
          fi
        fi
        echo -e "$RANDOM\tsh $projectDir/sh/classify.sh -m m $LargeType \"$SmallType\" $ctORag $bedFile"
      done
    done
  done| sort| cut -f2- > $projectDir/classify.tmp
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
      qsub -o /dev/null -e /dev/null $projectDir/sh/makeBigBed.sh -i $projectDir
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
