
# 使用するファイル
cat << '=============================================' > /dev/null
# http://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/wgEncodeGencodeUniProtV28.txt.gz
ENST00000441888.4  F2Z381  F2Z381  TrEMBL  

# http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/ensemblToGeneName.txt.gz
ENST00000441888  POU5F1    
ENST00000259915  POU5F1    

# http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/refFlat.txt.gz
 1  POU5F1                            POU5F1                            
 2  NM_001285987                      NM_001285987                      
 3  chr6_mann_hap4                    chr6_mcf_hap5                     
 4  -                                 -                                 
 5  2480457                           2514036                           
 6  2483306                           2516885                           
 7  2480721                           2514300                           
 8  2482298                           2515877                           
 9  4                                 4                                 
10  2480457,2481250,2481693,2482057,  2514036,2514829,2515272,2515636,  
11  2480988,2481409,2481824,2483306,  2514567,2514988,2515403,2516885,  

# http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/ensGene.txt.gz
 1  822                                            
 2  ENST00000441888                                
 3  chr6                                           
 4  -                                              
 5  31132118                                       
 6  31148508                                       
 7  31132377                                       
 8  31133416                                       
 9  5                                              
10  31132118,31132904,31133347,31133703,31148395,  
11  31132644,31133063,31133478,31133824,31148508,  
12  0                                              
13  ENSG00000204531                                
14  cmpl                                           
15  cmpl                                           
16  0,0,0,-1,-1,                                   
=============================================

# 関数定義
function id2symbol() {
  curl -s "$2"| gunzip| sed 's/\./\t/'| awk -F '\t' -v OFS='\t' '
  BEGIN {
    while ((getline < "/lustre7/home/w3oki/chipatlas/lib/TSS/uniqueTSS.'$1'.bed") > 0) print $4, $4
    cmd1 = "curl -s '$3'| gunzip"
    cmd2 = "curl -s '$4'| gunzip"
    cmd3 = "curl -s '$5'| gunzip"
    cmd4 = "curl -s '$6'| gunzip"
    while (cmd1 | getline) {
      x[$1] = $2
      print $0 "\n" $2, $2
    }
    while (cmd2 | getline) print $2, $1 "\n" $1, $1
    while (cmd3 | getline) print $2, $1 "\n" $1, $1
    while (cmd4 | getline) print $13, x[$2]
  } length(x[$1] > 0) {
    print $3, x[$1]
  }'| awk -F '\t' 'length($2) > 0 && !a[$0]++'| tr -d ';'| tac > "/lustre7/home/w3oki/chipatlas/lib/id2symbol/id2symbol.$1.tsv"
}

# Human
id2symbol hg19\
  http://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/wgEncodeGencodeUniProtV28.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/ensemblToGeneName.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/refFlat.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/refFlat.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/ensGene.txt.gz
  
# Mouse
id2symbol mm9\
  http://hgdownload.soe.ucsc.edu/goldenPath/mm10/database/wgEncodeGencodeUniProtVM18.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/mm9/database/ensemblToGeneName.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/mm10/database/refFlat.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/mm9/database/refFlat.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/mm9/database/ensGene.txt.gz

# Rat
id2symbol rn6\
  DUMMY\
  http://hgdownload.soe.ucsc.edu/goldenPath/rn6/database/ensemblToGeneName.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/rn6/database/refFlat.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/rn6/database/refFlat.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/rn6/database/ensGene.txt.gz

# ハエ
id2symbol dm3\
  DUMMY\
  http://hgdownload.soe.ucsc.edu/goldenPath/dm6/database/ensemblToGeneName.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/dm6/database/refFlat.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/dm6/database/refFlat.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/dm6/database/ensGene.txt.gz

# 線虫
id2symbol ce10\
  DUMMY\
  http://hgdownload.soe.ucsc.edu/goldenPath/ce11/database/ensemblToGeneName.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/ce11/database/refFlat.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/ce10/database/refFlat.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/ce11/database/ensGene.txt.gz

# 酵母
id2symbol sacCer3\
  DUMMY\
  http://hgdownload.soe.ucsc.edu/goldenPath/sacCer3/database/ensemblToGeneName.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/sacCer3/database/xenoRefFlat.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/sacCer3/database/xenoRefFlat.txt.gz\
  http://hgdownload.soe.ucsc.edu/goldenPath/sacCer3/database/ensGene.txt.gz


# 結果の例
cat << '===' > /dev/null
POU5F1           POU5F1  # Gene symbol
ENST00000259915  POU5F1  # ENST
ENST00000513407  POU5F1  # ENST
NM_001285987     POU5F1  # Refseq
NM_203289        POU5F1  # Refseq
ENSG00000204531  POU5F1  # ENSG
ENSG00000237582  POU5F1  # ENSG
B5B8N7           POU5F1  # UniProt
B5B8N8           POU5F1  # UniProt
===

