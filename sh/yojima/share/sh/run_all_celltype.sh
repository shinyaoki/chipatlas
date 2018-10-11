#!/bin/sh
#$ -S /bin/sh
cd /home/okishinya/Collabo/yojima/share/ChipAtlasAnnotation

sh process_unclassified.sh label_feature celltype 2 4 10
g++ -o trans trans_svm.cpp
./trans celltype 10 training
./trans celltype 10 curated
sh process2.sh word_data celltype 2-4
./libsvm-3.22/svm-train -q -t 0 -c 0.1 -b 1 word_data/c10_unclassified_training_celltype_intl2f2-4gram.txt word_data/c10_cost1_unclassified_training_celltype_intl2f2-4gram.txt.model
./libsvm-3.22/svm-predict -b 1 word_data/c10_unclassified_curated_celltype_intl2f2-4gram.txt word_data/c10_cost1_unclassified_training_celltype_intl2f2-4gram.txt.model word_data/output_c10_cost1_unclassified_curated_celltype_intl2f2-4gram.txt