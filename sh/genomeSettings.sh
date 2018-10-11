#!/bin/sh
#$ -S /bin/sh

projectDir=$1
Genome=$2

# check_sum (bowtie index)
md5_BI_hg18=b28f0d75c03356cd2328d8c47f6e06d4  
md5_BI_hg19=ce66e70b2bae64968f3fffd7011ab696  
md5_BI_mm10=67bf98b66a1ec77c6c644f456270ff34  
md5_BI_mm9=46a9f46ab7fb986e7a5853eccd20894a  
md5_BI_rn4=2102a3e348e7c0728e492132bae0e12d  
# check_sum (genome)
md5_WG_canFam3=1f59de31d797c5d9b903ae05d894e90c  
md5_WG_ce10=3d0bab4bc255fc5b3276a476e13d230c  
md5_WG_danRer6=3b313a0c28b02b6b2cd5a63e0a7d9d7b  
md5_WG_danRer7=594146754ced7d10f39cab6a89569196  
md5_WG_fr3=0a37a55012bfa1197594097fcbd28f45  
md5_WG_galGal4=1a9f49ada1b3a10646ffb7f279202cdb  
md5_WG_mm10=fcfcc276799031793a513e2e9c07adad  
md5_WG_rn5=ef5675dfd54afd9e587646be497e2672  
md5_WG_xenTro3=dd5c31e1c637c867eff9144ff64a7776  
md5_WG_ce6=574c756c7d69a690b77c40ec09f23b16  
md5_WG_dm2=242003883f7271ca7ab1a708cba4c7ff  
md5_WG_oryLat2=f744c52b47dcaea30379a976d4d9a360  
md5_WG_dm3=8699f76606a48f79fc4c0215f731c328  
md5_WG_fr2=abc8cf2c8688a26ca038101a86fe39e6  
md5_WG_sacCer2=8c5bc40e2c77ed5e3988a9d1c36534a3  
md5_WG_sacCer3=08ac8cc0d3005d068049dffa9be22bc4  
md5_WG_hg19=bcdbfbe9da62f19bee88b74dabef8cd3
md5_WG_hg18=05e8d31e39545273914397ad6204448e
md5_WG_mm8=6c2f887e2352f8f8e4578642eb266c00
md5_WG_mm9=e47354d24b9d95e832c337d42b9f8f71
md5_WG_rn4=9f0ed3cd87ab900be5e8157dbeaee12e
md5_WG_canFam2=2b35abba54ce445cb3c0bce13102a337
md5_WG_galGal3=f240b8b991f6f6e97308d6decf5a9b77
# check_sum (chromInfo)
md5_CI_hg18=8935ade7941552eade3f30b6ff90ad78
md5_CI_hg19=2222cbb04b6c8d38e575d8aa7c2ea75a
md5_CI_mm8=06df39dea6ab662dc89d326806154260
md5_CI_mm9=c4aa404721d8e916586de26435c26644
md5_CI_rn4=4a2212fde31cca1fc0d0fb16320a5f56
md5_CI_canFam2=4de80bb52006d9253486ebce5fd7c10d
md5_CI_galGal3=3bb2bfbd322d65d54d3b9e1844fe7332
md5_CI_ce10=810ea2a3d2e4c3e4a425962f97d5b938
md5_CI_ce6=7123e84cd1698901d14b452a374f7068
md5_CI_galGal4=d630a432e0af3fdf6b3afdc2a7915a7e
md5_CI_canFam3=9534fedcf6ead5137a1838a2a46a02a4
md5_CI_fr3=1038a9d66596b5c7acc01c5e02794ea2
md5_CI_mm10=bfe45c15d5e3e04156f0600e46d5941d
md5_CI_rn5=8a52d2a6eae4f7974a0d6c49627a1f07
md5_CI_xenTro3=c9e766f968e94d8bc3cc8bc974a2c477
md5_CI_danRer7=e698de9784cf764855155765e7fe663f
md5_CI_danRer6=657584ccfa1f45e6fc4298cf7b0058db
md5_CI_dm3=08072c4e1343d7d04ef99c7635dda5d9
md5_CI_fr2=12ccce49f375e957408873ff251c2cdc
md5_CI_sacCer2=1d317cdf00812622f09e7a7b21475717
md5_CI_sacCer3=1a0e33283e6e77ca53372811625beabb
md5_CI_dm2=6691e10c9438241e054a3f96c258bfa1
md5_CI_oryLat2=1cc0798c1133693eff43b991f3b47b18

case "$Genome" in
  hg18 | hg19 | mm10 | mm9 | rn4) 
    suffix="xxx"; idx="DL" ;;      # bowtie index is downloadable（.2bit genome）
  ce10 | ce6 | galGal4 | canFam3 | fr3 | rn5 | xenTro3 | danRer7 | danRer6 | mm8)
    suffix="2bit"; idx="Build" ;;   # bowtie index is unavailable（.2bit genome）
  dm3 | fr2 | sacCer2 | sacCer3 | canFam2 | galGal3)
    suffix="tar.gz"; idx="Build" ;; # bowtie index is unavailable（.tar.gz genome）
  dm2)
    suffix="zip"; idx="Build" ;;    # bowtie index is unavailable（.zip genome）
  oryLat2)
    suffix="gz"; idx="Build" ;;     # bowtie index is unavailable（.gz genome）
esac

case $suffix in 
  2bit)
    ucscGDL="http://hgdownload.soe.ucsc.edu/goldenPath/$Genome/bigZips/$Genome.2bit" ;;
  tar.gz)
    ucscGDL="http://hgdownload.soe.ucsc.edu/goldenPath/$Genome/bigZips/chromFa.tar.gz" ;;
  zip)
    ucscGDL="http://hgdownload.soe.ucsc.edu/goldenPath/$Genome/bigZips/chromFa.zip" ;;
  gz)
    ucscGDL="http://hgdownload.soe.ucsc.edu/goldenPath/$Genome/bigZips/$Genome.fa.gz" ;;
esac

ucscURL="http://hgdownload.soe.ucsc.edu/downloads.html"
ucscChI="ftp://hgdownload.cse.ucsc.edu/goldenPath/"$Genome"/database/chromInfo.txt.gz"
bowiURL="http://bowtie-bio.sourceforge.net/bowtie2/index.shtml"
bowiDL="ftp://ftp.ccb.jhu.edu/pub/data/bowtie2_indexes/"$Genome".zip"

mdCurl() { # $1=Adress, $2=Output, $3=md5
  mdcretval=0
  
  for num in `seq 30` ; do
#   curl -y60 -Y1 -C - -o $2 $1
    bin/ntcurl -o "-y60 -Y1 -C - -o $2" $1
    ori_sum=$3
    DL_sum=`md5sum $2 | cut -d ' ' -f1`
    if [ "$ori_sum" = "$DL_sum" ] ; then
      mdcretval=1
      break
    fi
    sleep 10
  done
}

# ------------------------------------------------------------------------
#                              Main script
# ------------------------------------------------------------------------

# Download of whole genome sequence
if [ $suffix != "xxx" ]; then
  oriSum=`eval echo '$md5_WG_'$Genome`
  mdCurl $ucscGDL $projectDir/lib/whole_genome_fa/$Genome.$suffix $oriSum
  
  if [ "$mdcretval" = "1" ] ; then
    echo "Converting into Fasta format..."  
    case $suffix in 
      2bit)  # Decompression with twoBitToFa
        $projectDir/bin/twoBitToFa $projectDir/lib/whole_genome_fa/$Genome.2bit $projectDir/lib/whole_genome_fa/$Genome.fa
        rm $projectDir/lib/whole_genome_fa/$Genome.2bit
        ;;
      *)     # Decompression with tar, unzip or gunzip
        mkdir -p $projectDir/lib/whole_genome_fa/$Genome
    
        case $suffix in
          tar.gz)
            tar xvzf $projectDir/lib/whole_genome_fa/$Genome.$suffix -C $projectDir/lib/whole_genome_fa/$Genome
            mv $projectDir/lib/whole_genome_fa/$Genome/*/*.fa $projectDir/lib/whole_genome_fa/$Genome/ ;;
          zip)
            unzip -o $projectDir/lib/whole_genome_fa/$Genome.$suffix -d $projectDir/lib/whole_genome_fa/$Genome ;;
          gz)
            gunzip -c $projectDir/lib/whole_genome_fa/$Genome.$suffix > $projectDir/lib/whole_genome_fa/$Genome/$Genome ;;
        esac
      
        cat $projectDir/lib/whole_genome_fa/$Genome/* > $projectDir/lib/whole_genome_fa/$Genome.fa
        rm -r $projectDir/lib/whole_genome_fa/$Genome
        rm $projectDir/lib/whole_genome_fa/$Genome.$suffix
        ;;
    esac
    
  else
    echo "$Genome.$suffix could not be downloaded."  
    exit
  fi

  echo "Fasta file has been generated. ($Genome.fa)"  
  echo ""
fi


# Download or build of Bowtie index
case $idx in 
  DL)
    echo "Downloading $Genome bowtie indexes."  
    
    oriSum=`eval echo '$md5_BI_'$Genome`
    mdCurl $bowiDL $projectDir/lib/bowtie_index/$Genome.zip $oriSum

    if [ "$mdcretval" = "1" ] ; then
      unzip -o $projectDir/lib/bowtie_index/$Genome.zip -d $projectDir/lib/bowtie_index
      rm $projectDir/lib/bowtie_index/$Genome.zip
    else
      echo "$Genome bowtie indexes could not be downloaded."  
      exit
    fi
    ;;
  Build)
    echo "Building $Genome bowtie indexes."  
    $projectDir/bin/bowtie2-2.2.2/bowtie2-build $projectDir/lib/whole_genome_fa/$Genome.fa $projectDir/lib/bowtie_index/$Genome
    ;;
esac

echo "Bowtie index has been generated."  
echo ""

# Download of chromInfo
echo "Downloading chromInfo..."  
oriSum=`eval echo '$md5_CI_'$Genome`
mdCurl $ucscChI $projectDir/lib/genome_size/chromInfo.txt.gz $oriSum

if [ "$mdcretval" = "1" ] ; then
  gunzip -c $projectDir/lib/genome_size/chromInfo.txt.gz > $projectDir/lib/genome_size/chromInfo.txt
  cat $projectDir/lib/genome_size/chromInfo.txt | cut -f1,2 | sort -k2nr > $projectDir/lib/genome_size/$Genome.chrom.sizes
  rm $projectDir/lib/genome_size/chromInfo.txt.gz $projectDir/lib/genome_size/chromInfo.txt
  echo ""
  echo "$Genome libraries have been prepared."  
else
  echo "$Genome chromInfo could not be downloaded."  
  exit
fi





