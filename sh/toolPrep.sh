#!/bin/sh
#$ -S /bin/sh

projectDir=$1

# Function (Download of tools)
mdCurl() { # $1=URL $2=output $3=md5 $4=devbio_tool
  for i in `seq 10`; do
    curl -y60 -Y1 -C - -o $2 $1
    DL_sum=`md5sum $2 | cut -d ' ' -f1`
    if [ "$3" = "$DL_sum" ] ; then
      break
    fi
    sleep 5
  done
}

# Function (Final check)
finalCheck() {  # $1=Tool, $2=Command, $3=lines
  binLine=`echo $2| sh`
  if [ "$binLine" != "$3" ]; then
    echo $1
  fi
}


# md5
md5_BedT=e7209a6f88f8df844474369bd40db8be
md5_BoWt=a3a001a8c97b991f6beb596f6c9674b6
md5_MCS2=ad105b9ad25bc2eedc78c38d54cf76e8
md5_SraT=904a57b67c13b94623c8e13520b4a387
md5_SamT=ff8b46e6096cfb452003b1ec5091d86a
md5_tBtF=d202a7204fdf377e3aecf03c7939fb75
md5_bTBB=811f84b7b5a953843c3369fa9db8844e
md5_bGBW=1aad21ab353d00bb9bf8e56aca4598b1
md5_bdCP=439ecb927959837e1ea37c60fea9def0
md5_IGVt=a7f8c8b447328e166bd637e34b16ed56
STmirror=`curl http://sourceforge.net/projects/samtools/files/samtools/0.1.19/samtools-0.1.19.tar.bz2/download|grep mirro|cut -d '=' -f5| cut -d '"' -f1`
B2Lmirror=`curl http://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.2.2/bowtie2-2.2.2-linux-x86_64.zip/download|grep mirro|cut -d '=' -f5| cut -d '"' -f1`


# MACS2
export PYTHONPATH=$projectDir/bin/MACS2-2.1.0/$projectDir/bin/MACS2-2.1.0/lib/python2.7/site-packages:$PYTHONPATH
echo -e "\e[32mInstalling MACS2...\e[m"  
mdCurl https://pypi.python.org/packages/source/M/MACS2/MACS2-2.1.0.20140616.tar.gz $projectDir/bin/MACS2-2.1.0.20140616.tar.gz $md5_MCS2 MACS2-2.1.0.20140616.tar.gz
tar xvzf $projectDir/bin/MACS2-2.1.0.20140616.tar.gz -C $projectDir/bin
mv $projectDir/bin/MACS2-2.1.0.20140616 $projectDir/bin/MACS2-2.1.0
cd $projectDir/bin/MACS2-2.1.0
python setup.py install --prefix $projectDir/bin/MACS2-2.1.0
cd


# Aspera-connect
echo -e "\e[32mInstalling Aspera connect...\e[m"  
curl http://download.asperasoft.com/download/sw/connect/3.5/aspera-connect-3.5.1.92523-linux-32.sh > aspera-connect-3.5.1.92523-linux-32.sh 
sh aspera-connect-3.5.1.92523-linux-32.sh
rm aspera-connect-3.5.1.92523-linux-32.sh
mkdir .putty
echo -e "rsa2@22:ftp-trace.ncbi.nlm.nih.gov 0x23,0xf2b8e967d1d47cb79763aaa45e152dfad4f2292bba2bba8032139d1fabb6d781045815d05e4bf782158aba7645fbbb32e24db8e8d15005db2ef1dac65be3ca077ff2d5f2d0aa8c7f2006f612233e2fe13061dc4a721d4623b4f0ef5fd4da8a35ca4169404994672daf9e02f24f840e384dbb5c94d6391a49bdbe612091a28e45
" > .putty/sshhostkeys 


# bedtools 
echo -e "\e[32mInstalling bedtools...\e[m"  
mdCurl https://bedtools.googlecode.com/files/BEDTools.v2.17.0.tar.gz $projectDir/bin/BEDTools.tar.gz $md5_BedT BEDTools.v2.17.0.tar.gz
tar xvzf $projectDir/bin/BEDTools.tar.gz -C $projectDir/bin
cd $projectDir/bin/bedtools-2.17.0
make
cd


# bowtie2
echo -e "\e[32mInstalling bowtie2...\e[m"  
mdCurl http://$B2Lmirror.dl.sourceforge.net/project/bowtie-bio/bowtie2/2.2.2/bowtie2-2.2.2-linux-x86_64.zip $projectDir/bin/bowtie2-2.2.2-linux-x86_64.zip $md5_BoWt bowtie2-2.2.2-linux-x86_64.zip
unzip -d $projectDir/bin/ $projectDir/bin/bowtie2-2.2.2-linux-x86_64.zip


# sratoolkit
echo -e "\e[32mInstalling sratoolkit...\e[m"
mdCurl http://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/2.3.2-4/sratoolkit.2.3.2-4-ubuntu64.tar.gz $projectDir/bin/sratoolkit.2.3.2-4-ubuntu64.tar.gz $md5_SraT sratoolkit.2.3.2-4-ubuntu64.tar.gz
tar xvzf $projectDir/bin/sratoolkit.2.3.2-4-ubuntu64.tar.gz -C $projectDir/bin

# samtools
echo -e "\e[32mInstalling samtools...\e[m"  
mdCurl http://$STmirror.dl.sourceforge.net/project/samtools/samtools/0.1.19/samtools-0.1.19.tar.bz2 $projectDir/bin/samtools-0.1.19.tar.bz2 $md5_SamT samtools-0.1.19.tar.bz2
cd $projectDir/bin/
bzip2 -dc samtools-0.1.19.tar.bz2 | tar xvf - 
cd samtools-0.1.19
make
cd

# IGVtools
echo -e "\e[32mInstalling igvtools...\e[m"  
mdCurl http://www.broadinstitute.org/igv/projects/downloads/igvtools_2.3.47.zip $projectDir/bin/igvtools_2.3.47.zip $md5_IGVt igvtools_2.3.47.zip
unzip -o $projectDir/bin/igvtools_2.3.47.zip -d $projectDir/bin/
rm $projectDir/bin/igvtools_2.3.47.zip

# UCSC utilities
echo -e "\e[32mInstalling UCSC utilities...\e[m"
mdCurl http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/twoBitToFa $projectDir/bin/twoBitToFa $md5_tBtF twoBitToFa
mdCurl http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v287/bedToBigBed $projectDir/bin/bedToBigBed $md5_bTBB bedToBigBed
mdCurl http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedGraphToBigWig $projectDir/bin/bedGraphToBigWig $md5_bGBW bedGraphToBigWig
mdCurl http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedClip $projectDir/bin/bedClip $md5_bdCP bedClip
chmod +x $projectDir/bin/twoBitToFa
chmod +x $projectDir/bin/bedToBigBed
chmod +x $projectDir/bin/bedGraphToBigWig
chmod +x $projectDir/bin/bedClip

# Final Check
echo ""
echo -e "\e[32mFinal check for installation of CLI tools.\e[m"  

FC=`{
  finalCheck MACS2 "$projectDir/bin/MACS2-2.1.0/$projectDir/bin/MACS2-2.1.0/bin/macs2 -h| wc -l" 40
  finalCheck bedGraphToBigWig "$projectDir/bin/bedGraphToBigWig 2>&1| wc -l" 15
  finalCheck bedToBigBed "$projectDir/bin/bedToBigBed 2>&1| wc -l" 29
  finalCheck bedtools-2.17.0 "$projectDir/bin/bedtools-2.17.0/bin/genomeCoverageBed 2>&1| wc -l" 89
  finalCheck bowtie2-2.2.2 "$projectDir/bin/bowtie2-2.2.2/bowtie2 2>&1| wc -l" 124
  finalCheck samtools-0.1.19 "$projectDir/bin/samtools-0.1.19/samtools 2>&1| wc -l" 26
  finalCheck sratoolkit.2.3.2-4-mac64 "$projectDir/bin/sratoolkit.2.3.2-4-ubuntu64/bin/fastq-dump 2>&1| wc -l" 9
  finalCheck twoBitToFa "$projectDir/bin/twoBitToFa 2>&1| wc -l" 24
  finalCheck bedClip "$projectDir/bin/bedClip 2>&1| wc -l" 6
}`
fcNum=`echo $FC| awk '{printf "%d", NF}'`

if [ "$fcNum" -gt "0" ]; then
  echo -e "\e[32mThe following tools could not be installed.\e[m"  
  echo -e "\e[31m$FC\e[m"  
  echo ""
  exit
else
  echo -e "\e[32m  OK.\e[m"  
  echo ""
fi


# Removal of archives
rm $projectDir/bin/BEDTools.tar.gz
rm $projectDir/bin/bowtie2-2.2.2-linux-x86_64.zip
rm $projectDir/bin/sratoolkit.2.3.2-4-ubuntu64.tar.gz
rm $projectDir/bin/samtools-0.1.19.tar.bz2
rm $projectDir/bin/MACS2-2.1.0.20140616.tar.gz


echo -e "\e[32mInitial settings have been completed.\e[m"  
