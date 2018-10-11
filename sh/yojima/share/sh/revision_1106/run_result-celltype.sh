#!/bin/sh
#$ -S /bin/sh
cd /home/okishinya/Collabo/yojima/share/ChipAtlasAnnotation
R < acc_eachclass_one_celltype.R
python extract-lines_celltype.py true
python extract-lines_celltype.py false