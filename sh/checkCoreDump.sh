#!/bin/sh
#$ -S /bin/sh

# sh chipatlas/sh/checkCoreDump.sh

projectDir=`echo $0| sed 's[/sh/checkCoreDump.sh[['`

for Genome in `ls $projectDir/results`; do
  for SRX in `ls $projectDir/results/$Genome| grep '[SDE]RX[0-9][0-9][0-9][0-9]'`; do
    ls $projectDir/results/$Genome/$SRX| grep -c "core\."| awk -v Genome=$Genome -v SRX=$SRX '{
      printf "%s\t%s\t%s\n", Genome, SRX, ($1 > 0) ? "Core dump" : "Unknown"
    }'
  done
done

