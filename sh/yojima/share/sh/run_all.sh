#!/bin/sh
#$ -S /bin/sh
if [ $# -ne 2 ]; then
  echo "The number of parameter is: $#" 1>&2
  echo "Need to type 3 parameters:
        1.type of creature: hg19 or mm9 or ...
        2.data type: celltype or antigen" 1>&2
  exit 1
fi

creature=$1
type=$2
today=$(date "+%Y%m%d")
cd /home/okishinya/Collabo/yojima/share/ChipAtlasAnnotation/
#cd /home/okishinya/Collabo/yojima/share/ChipAtlasAnnotation

sh process_unclassified_extend2.sh label_feature ${type} 2 4 10 ${creature} ${today}
g++ -o trans trans_svm.cpp
./trans ${type} 10 training ${creature} ${today}
./trans ${type} 10 curated ${creature} ${today}
sh process2.sh word_data ${type} 2-4 ${creature} ${today}
./libsvm-3.22/svm-train -q -t 0 -c 0.1 -b 1 word_data/${creature}/${today}/c10_unclassified_training_${type}_intl2f2-4gram.txt word_data/${creature}/${today}/c10_cost1_unclassified_training_${type}_intl2f2-4gram.txt.model
./libsvm-3.22/svm-predict -b 1 word_data/${creature}/${today}/c10_unclassified_curated_${type}_intl2f2-4gram.txt word_data/${creature}/${today}/c10_cost1_unclassified_training_${type}_intl2f2-4gram.txt.model word_data/${creature}/${today}/output_c10_cost1_unclassified_curated_${type}_intl2f2-4gram.txt