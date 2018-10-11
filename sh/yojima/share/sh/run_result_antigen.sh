#!/bin/sh
#$ -S /bin/sh
cd /home/okishinya/Collabo/yojima/share/ChipAtlasAnnotation
R < acc_eachclass_one_antigen.R --save
python extract-lines_antigen.py true
python extract-lines_antigen.py false