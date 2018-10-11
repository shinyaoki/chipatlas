#!/bin/sh
#$ -S /bin/sh

# sh chipatlas/sh/metaPrep.sh chipatlas

projectDir=$1

# 最新の Metadata_Full の名前を取得
MetadataFull=`curl ftp://ftp.ncbi.nlm.nih.gov/sra/reports/Metadata/| awk '$9 ~ "NCBI_SRA_Metadata_Full" {print $9}'| tail -n1| cut -d '.' -f1`  # NCBI_SRA_Metadata_Full_20170202.tar.gz

# MetadataFull のダウンロード (3 分)
while :; do
  rm -f $MetadataFull.tar.gz
  wget ftp://ftp.ncbi.nlm.nih.gov/sra/reports/Metadata/$MetadataFull.tar.gz && break
  sleep 10
done

# experiment.xml と SRA_Accessions を部分解凍 (約 10 分)
mkdir $MetadataFull
key=`less $MetadataFull.tar.gz | head -n1| awk '{
  if ($NF ~ "NCBI_SRA_Metadata_Full") printf 0
  else if ($NF ~ "RA") printf 1
  else printf 2
}'`
if [ $key = 0 ]; then
  tar xzf ~/$MetadataFull.tar.gz $MetadataFull/*/*.experiment.xml $MetadataFull/SRA_Accessions $MetadataFull/SRA_Run_Members
elif [ $key = 1 ]; then
  cd $MetadataFull; tar xzf ~/$MetadataFull.tar.gz */*.experiment.xml SRA_Accessions SRA_Run_Members
elif [ $key = 2 ]; then
  cd $MetadataFull; tar xzf ~/$MetadataFull.tar.gz ./*/*.experiment.xml ./SRA_Accessions ./SRA_Run_Members
fi
cd


# SRA_Accessions を整形 (2 分)
cat $MetadataFull/SRA_Accessions |awk -F '\t' '{
  if ($7 == "EXPERIMENT" && $18 != "-") print $1 "\t" $2 "\t" $12 "\t" $13 "\t" $18 "\t" $19 "\t" $4
#                                             SRX     SRA     SRS      SRP      SAMN     PRJNA    Updated
}'|sort|uniq| tr ' ' '_' > SRA_Accessions_experiment.tab

#  1  SRX023509             # SRX
#  2  SRA020972             # SRA
#  3  SRS085026             # SRS
#  4  SRP002862             # SRP
#  5  SAMN00017052          # SAMN
#  6  PRJNA127937           # PRJNA
#  7  2013-09-23T16:45:14Z  # Update



# biosample_set のダウンロード、整形 (18 分)
while :; do
  rm -f biosample_set.xml.gz
  wget ftp://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz && break
  sleep 10
done
cat biosample_set.xml.gz| gunzip| tr '>' '<'| awk -F '<' -v SAMN="xxx" -v ORGN="xxx" '{
  if (substr($0,1,21) == "    <Id db=\"BioSample") SAMN=$3
  if (substr($0,1,14) == "    <Organism ")         ORGN=$2
  if (substr($0,1,30) == "    <Attribute attribute_name=") {
    split($0, arr, "\"")
    ATTR = ATTR"\t"arr[2]"="$3
  }
  if ($0 == "</BioSample<") {
    sub("/", "", ORGN)
    print SAMN "\t" ORGN ATTR
    SAMN="xxx"
    ORGN="xxx"
    ATTR=""
  }
}'| awk '{
  if ($1 != "xxx" && $2 != "xxx") print
}'| sort| uniq > biosample_set.tab
rm biosample_set.xml.gz

#  1  SAMN00017052                                               # SAMN
#  2  Organism>taxonomy_id="10090">taxonomy_name="Mus>musculus"  # Organism
#  3  source_name=ES>cell                                        # Attributes
#  4  strain=CCE                                                 # Attributes
#  5  antibody=Oct4                                              # Attributes
#  6  antibody>manufacturer=Santa>Cruz                           # Attributes
#  7  antibody>catalog>number=sc8628                             # Attributes


# experiment.xml の整形 (30 分)
less $MetadataFull.tar.gz| grep experiment.xml| awk '{print "'$MetadataFull'" substr($NF,2)}'| xargs cat| tr '>' '<'| awk -F '<' '{
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
}'| tr ' ' '_' > SRA_Metadata_Experiments.tab

less $MetadataFull.tar.gz| awk -F '/' ' $0 ~ "experiment.xml" {
  sub(".experiment.xml", "", $NF)
  print "'$MetadataFull'/" $NF "/" $NF ".experiment.xml"
}'| xargs cat| tr '>' '<'| awk -F '\t' '
BEGIN {
  while ((getline < "'$MetadataFull'/SRA_Run_Members") > 0) if ($1 ~ "RR" && $3 ~ "RX") x[$3] = x[$3] "\t" $1
  FS = "<"
} {
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
  
  if ($0 == "        <LIBRARY_LAYOUT<") {
    getline
    if ($0 == "          <SINGLE/<") sorp = 0
    else sorp = 1
  }
  if ($0 ~ "</EXPERIMENT<") {
    print arr[1] "\t" sorp x[arr[1]] > "chipatlas/lib/metadata/SRA_Metadata_RunInfo.tab"
    for (i=1; i<10; i++) {
      if (arr[i] == "") arr[i] = "xxx"
      printf "%s\t", arr[i]
      arr[i] = "xxx"
    }
    print arr[10]
  }
}'| tr ' ' '_' > SRA_Metadata_Experiments.tab

#  1  SRX023509                 # SRX
#  2  GSM566277: Oct4_ChIP-seq  # TITLE
#  3  ChIP-Seq                  # LIBRARY_STRATEGY
#  4  GENOMIC                   # LIBRARY_SOURCE
#  5  ChIP                      # LIBRARY_SELECTION
#  6  0                         # READ_INDEX
#  7  Application Read          # READ_CLASS
#  8  Forward                   # READ_TYPE
#  9  1                         # BASE_COORD
# 10  Illumina Genome Analyzer  # INSTRUMENT_MODEL


# メタデータの統合 (2 分)
cat biosample_set.tab| sed 's/&/__ANDnoKAWARI__/g'| awk -F '\t' -v OFS='\t' '
BEGIN {
  while ((getline < "SRA_Metadata_Experiments.tab") > 0) x[$1] = $0
  while ((getline < "SRA_Accessions_experiment.tab") > 0) {
    y[$5] = $0 "\t" x[$1] SUBSEP y[$5] # y[SAMN]
    z[$5]++
  }
  delete x
} {
  if (z[$1] > 0) {
    gsub(SUBSEP, "\t" $0 "\n", y[$1])  # gsub の replacement 中にスペシャルキャラクタ ＆ があると、それは regexp にマッチした部分文字列を表す。
    printf "%s", y[$1]
  }
  delete z[$1]
  delete y[$1]
}'| awk -F '\t' -v OFS='\t' '{
  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s", $1, $5, $9, $10, $11, $12, $13, $14, $15, $16, $17, $2, $3, $4, $6, $7, $19
  for (i=20; i<=NF; i++) printf "\t%s", $i
  printf "\n"
}'| sed 's/__ANDnoKAWARI__/\&/g'| sort| uniq > $projectDir/lib/metadata/$MetadataFull.metadata.tab

rm SRA_Metadata_Experiments.tab biosample_set.tab SRA_Accessions_experiment.tab $MetadataFull.tar.gz
rm -rf $MetadataFull

# NCBI_SRA_Metadata_Full_20170202.metadata.tab
 1  SRX023509                                                  
 2  SAMN00017052                                               
 3  GSM566277:_Oct4_ChIP-seq                                   
 4  ChIP-Seq                                                   
 5  GENOMIC                                                    
 6  ChIP                                                       
 7  0                                                          
 8  Application_Read                                           
 9  Forward                                                    
10  1                                                          
11  Illumina_Genome_Analyzer                                   
12  SRA020972                                                  
13  SRS085026                                                  
14  SRP002862                                                  
15  PRJNA127937                                                
16  2013-09-23T16:45:14Z                                       
17  Organism taxonomy_id="10090" taxonomy_name="Mus musculus"  
18  source_name=ES cell                                        
19  strain=CCE                                                 
20  antibody=Oct4                                              
21  antibody manufacturer=Santa Cruz                           
22  antibody catalog number=sc8628                             
