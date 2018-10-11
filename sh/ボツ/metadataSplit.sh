#!/bin/sh
#$ -S /bin/sh

fn=$1
MetadataFullDir=$2
# qsub -o /dev/null -e /dev/null -pe def_slot 1 $projectDir/sh/metadataSplit.sh "$j" $projectDir/lib/metadata/$MetadataFullDir

for i in `cat $fn`; do # i=SRAxxxx
  cat $MetadataFullDir/$i/$i.experiment.xml| tr '>' '<'| awk -F '<' '{
    if (substr($0,1,18) == "      <PRIMARY_ID<")          arr[1]  = $3 # SRX
    if (substr($0,1,11) == "    <TITLE<")                 arr[2]  = $3
    if (substr($0,1,26) == "        <LIBRARY_STRATEGY<")  arr[3]  = $3
    if (substr($0,1,24) == "        <LIBRARY_SOURCE<")    arr[4]  = $3
    if (substr($0,1,27) == "        <LIBRARY_SELECTION<") arr[5]  = $3
    if (substr($0,1,24) == "            <READ_INDEX<")    arr[6]  = $3
    if (substr($0,1,24) == "            <READ_CLASS<")    arr[7]  = $3
    if (substr($0,1,23) == "            <READ_TYPE<")     arr[8]  = $3
    if (substr($0,1,24) == "            <BASE_COORD<")    arr[9]  = $3
    if (substr($0,1,26) == "        <INSTRUMENT_MODEL<")  arr[10] = $3
    if ($0 ~ "</EXPERIMENT<") {
      for (i=1; i<10; i++) {
        if (arr[i] == "") arr[i] = "xxx"
        printf "%s\t", arr[i]
        arr[i] = "xxx"
      }
      print arr[10]
    }
  }'>> $fn.txt
  rm -r $MetadataFullDir/$i
done

cat $fn.txt| tr ' ' '_' | sort| uniq > $fn.sort.txt
join $fn.sort.txt $MetadataFullDir/SRA_Accessions_experiment.tab| tr ' ' '\t'| sort -k14 > $fn.join.txt
join -1 14 $fn.join.txt $MetadataFullDir/biosample_set.tab | tr '> ' ' \t' > $fn.sample.txt
