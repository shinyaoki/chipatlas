#!/bin/sh
#$ -S /bin/sh

projectDir=$1

# 最新の MetadataFull の名前を取得
MetadataFull=`ftp -n -v ftp.ncbi.nlm.nih.gov << EOS | grep NCBI_SRA_Metadata_Full_2| awk '{print $9}'| sort| tail -n1
user anonymous \n
cd sra/reports/Metadata
ls
quit
EOS
`


# 最新の MetadataFull と biosample_set.xml をダウンロード、解凍
cd $projectDir/lib/metadata
ftp -n -v ftp.ncbi.nlm.nih.gov << EOS
user anonymous \n
ls
cd sra/reports/Metadata
get $MetadataFull
cd /biosample
get biosample_set.xml.gz
quit
EOS

tar zxvf $MetadataFull
gunzip biosample_set.xml.gz
rm $MetadataFull


# SRA_Accessions を整形
MetadataFullDir=`echo $MetadataFull| cut -d '.' -f1`
echo "$MetadataFullDir/SRA_Accessions_experiment.tab を作成中..."
cat $MetadataFullDir/SRA_Accessions |awk -F '\t' '{
  if ($7 == "EXPERIMENT" && $18 != "-") print $1 "\t" $2 "\t" $12 "\t" $13 "\t" $18 "\t" $19 "\t" $4
#                                             SRX     SRA     SRS      SRP      SAMN     PRJNA    Updated
}'|sort|uniq| tr ' ' '_' > $MetadataFullDir/SRA_Accessions_experiment.tab


# biosample_set を整形
echo "$MetadataFullDir/biosample_set.tab を作成中..."
cat biosample_set.xml | tr '>' '<'| awk -F '<' '{
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
}'| tr ' ' '>'| sort| uniq > $MetadataFullDir/biosample_set.tab
# $1=SAMN
# $2=Organism
# $3~Attribute


# Metadata_Full の名前を split し、experiment と sample 情報をひもづけする
rm -rf splitDir
mkdir splitDir
splitN=`ls $MetadataFullDir| wc -l| awk '{print int($1/100)}'`
ls $MetadataFullDir| grep -v "_" > metadataAccNo.txt
split -a 3 -l $splitN metadataAccNo.txt splitDir/

cd

ql=`sh $projectDir/sh/QSUB.sh mem`
for j in `ls $projectDir/lib/metadata/splitDir/*`; do
  qsub $ql -o /dev/null -e /dev/null -pe def_slot 1 $projectDir/sh/metadataSplit.sh "$j" $projectDir/lib/metadata/$MetadataFullDir
done

echo "$projectDir/lib/metadata/$MetadataFullDir.metadata.tab を作成中..."
while :; do
  qstatN=`qstat| awk '{if ($3 == "metadataSp") print}'| wc -l`
  if [ $qstatN -eq 0 ]; then
    cat $projectDir/lib/metadata/splitDir/*.sample.txt | awk -F '\t' '{
      printf "%s\t%s\t", $2, $1
      for (i=3; i<NF; i++) printf "%s\t", $i
      print $NF
    }'| sort > $projectDir/lib/metadata/$MetadataFullDir.metadata.tab
    break
  fi
done

# $1=SRX
# $2=SAMN
# $3=TITLE
# $4=LIBRARY_STRATEGY
# $5=LIBRARY_SOURCE
# $6=LIBRARY_SELECTION
# $7=READ_INDEX
# $8=READ_CLASS
# $9=READ_TYPE
# $10=BASE_COORD
# $11=INSTRUMENT_MODEL
# $12=SRA
# $13=SRS
# $14=SRP
# $15=PRJ
# $16=Update
# $17=Organism
# $18~Attribute

rm -r $projectDir/lib/metadata/splitDir $projectDir/lib/metadata/$MetadataFullDir
rm $projectDir/lib/metadata/biosample_set.xml $projectDir/lib/metadata/metadataAccNo.txt
