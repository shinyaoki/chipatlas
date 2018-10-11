#May 17, 2017
if [ $# -ne 5 ]; then
  echo "The number of parameter is: $#" 1>&2
  echo "Need to type 4 parameters: 
        1.folder directory: label_feature
        2.data type: celltype or antigen
        3.'n1' of ngram: from 1 to 10
        4.'n2' of ngram: from 1 to 10
        5.filter 'n' of class number" 1>&2
  exit 1
fi

dir=$1
type=$2
gram_n1=$3
gram_n2=$4
filter_n=$5

python count_unclassified.py label_feature/c1_mm9_${type}.txt ${filter_n} label_feature/c${filter_n}_unclassified_training_${type}.txt ${type}_curated_201702.tsv label_feature/c${filter_n}_unclassified_curated_${type}.txt

cat label_feature/c${filter_n}_unclassified_training_${type}.txt label_feature/c${filter_n}_unclassified_curated_${type}.txt > label_feature/c${filter_n}_unclassified_training_curated_${type}.txt

cut -f2 label_feature/c${filter_n}_unclassified_training_curated_${type}.txt > label_feature/c${filter_n}_unclassified_training_curated_${type}_l2.txt
cut -f1 label_feature/c${filter_n}_unclassified_training_curated_${type}.txt > label_feature/c${filter_n}_unclassified_training_curated_${type}_l1.txt
cut -f3- label_feature/c${filter_n}_unclassified_training_curated_${type}.txt > label_feature/c${filter_n}_unclassified_training_curated_${type}_feature.txt

python text-ngram2.py word_data ${type} ${gram_n1} ${gram_n2} ${filter_n} label_feature/c${filter_n}_unclassified_training_curated_${type}_l2.txt label_feature/c${filter_n}_unclassified_training_curated_${type}_intl2.txt
python text-ngram2.py word_data ${type} ${gram_n1} ${gram_n2} ${filter_n} label_feature/c${filter_n}_unclassified_training_curated_${type}_l1.txt label_feature/c${filter_n}_unclassified_training_curated_${type}_intl1.txt

paste label_feature/c${filter_n}_unclassified_training_curated_${type}_intl2.txt label_feature/c${filter_n}_unclassified_training_curated_${type}_feature.txt > label_feature/c${filter_n}_unclassified_training_curated_${type}_intl2_feature.txt

training_size=$(cat label_feature/c${filter_n}_unclassified_training_${type}.txt | wc -l)
curated_size=$(cat label_feature/c${filter_n}_unclassified_curated_${type}.txt | wc -l)

head -n ${training_size} label_feature/c${filter_n}_unclassified_training_curated_${type}_intl2_feature.txt > label_feature/c${filter_n}_unclassified_training_${type}_intl2_feature.txt
tail -n ${curated_size} label_feature/c${filter_n}_unclassified_training_curated_${type}_intl2_feature.txt > label_feature/c${filter_n}_unclassified_curated_${type}_intl2_feature.txt

cut -f1 label_feature/c${filter_n}_unclassified_training_${type}_intl2_feature.txt > label_feature/c${filter_n}_unclassified_training_${type}_intl2.txt
cut -f1 label_feature/c${filter_n}_unclassified_curated_${type}_intl2_feature.txt > label_feature/c${filter_n}_unclassified_curated_${type}_intl2.txt
cut -f2- label_feature/c${filter_n}_unclassified_training_${type}_intl2_feature.txt > label_feature/c${filter_n}_unclassified_training_${type}_feature.txt
cut -f2- label_feature/c${filter_n}_unclassified_curated_${type}_intl2_feature.txt > label_feature/c${filter_n}_unclassified_curated_${type}_feature.txt

python text-ngram2.py word_data ${type} ${gram_n1} ${gram_n2} ${filter_n}