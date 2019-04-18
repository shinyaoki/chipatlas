#!/bin/sh
#$ -S /bin/sh

# ==========================================================================================
# ML_curation.sh (初期モード)
# ==========================================================================================
# sh chipatlas/sh/ML_curation.sh initial

if [ $1 = "initial" ]; then
  rm -r Collabo/yojima/share/ChipAtlasAnnotation/label_feature
  rm -r Collabo/yojima/share/ChipAtlasAnnotation/word_data
  ql=`sh chipatlas/sh/QSUB.sh mem`
  for genome in `ls chipatlas/results`; do
    case $genome in
      mm9 | hg19) Nslot="4-";;
      *)          Nslot="1" ;;
    esac
    for TYPE in antigen celltype; do
      qsub $ql -pe def_slot $Nslot -e /dev/null -o /dev/null chipatlas/sh/ML_curation.sh $genome $TYPE
    done
  done
  exit
fi
  

    
# ==========================================================================================
# ML_curation.sh (qsub モード)
# ==========================================================================================
# qsub $ql -l s_vmem=16G -l mem_req=16G -e /dev/null -o /dev/null Collabo/yojima/share/sh/run_all.sh $genome $TYPE

genome=$1
creature=$genome
today=$(date "+%Y%m%d")
TYPE=$2  # antigen or celltype
type=`echo $TYPE| sed 's/antigen/ag/'| sed 's/celltype/ct/'`  # ag or ct

# フォルダの作成
mkdir -p Collabo/yojima/share/ChipAtlasAnnotation/label_feature/${creature}/${today}
mkdir -p Collabo/yojima/share/ChipAtlasAnnotation/word_data/${creature}/${today}

# 計算用のファイルの設置と実行
inData="chipatlas/classification/"$type"_Statistics."$genome".tab"
trainingData="Collabo/yojima/share/ChipAtlasAnnotation/label_feature/"$genome"/"$today"/c1_"$genome"_"$TYPE".txt"
testData="Collabo/yojima/share/ChipAtlasAnnotation/label_feature/"$genome"/"$today"/"$TYPE"_curated.tsv"
log="run_all_"$today"_"$genome"_"$TYPE"_log.txt"

sh chipatlas/sh/textForMachineLearning.sh "$inData" "$trainingData" "$testData"
sh Collabo/yojima/share/sh/run_all2.sh $genome $TYPE
  # Collabo/yojima/share/ChipAtlasAnnotation/word_data/GENOME/DATE 配下にいろんなファイルができる


# 結果の整理
fn1="Collabo/yojima/share/ChipAtlasAnnotation/label_feature/$genome/$today/c10_unclassified_training_"$TYPE"_intl2.txt"
fn2="Collabo/yojima/share/ChipAtlasAnnotation/label_feature/$genome/$today/c10_unclassified_training_"$TYPE".txt"
fn3="Collabo/yojima/share/ChipAtlasAnnotation/word_data/$genome/$today/output_c10_cost1_unclassified_curated_"$TYPE"_intl2f2-4gram.txt"
fn4="chipatlas/classification/"$type"_Statistics.$genome.tab"
paste "$fn1" "$fn2"| awk -F '\t' -v fn3="$fn3" -v fn4="$fn4" '
BEGIN {
  while ((getline < "/home/okishinya/chipatlas/sh/abbreviationList_AG.tab") > 0) x[$2] = $1
  while ((getline < "/home/okishinya/chipatlas/sh/abbreviationList_CT.tab") > 0) x[$2] = $1
} !z[$1,$3]++ {
  if ($3 ~ "_____") {
    split($3, a, "_____")
    y[$1] = x[a[1]] "@ " a[2]
  } else {
    y[$1] = "?"
  }
} END {
  FS = " "
  while ((getline < fn3) > 0) if (y[$1]) {
    i++
    z[i] = y[$1]
  }
  FS = "\t"
  while ((getline < fn4) > 0) {
    if ($1 == "SRA") {
      print "SRA\tSRX\tMGI\told\tnew\tpredict\tjudge"
    } else {
      if ($4 == $5) {
        j++
        print $0 "\t" z[j]
      } else {
        print
      }
    }
  }
}' > "$fn4".tmp
mv "$fn4".tmp "$fn4"


