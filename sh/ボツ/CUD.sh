#!/bin/sh
#$ -S /bin/sh

baseFN=$1
projectDir=$2
Genome=$3

gSize=$projectDir/lib/genome_size/$Genome.chrom.sizes

cat $baseFN.bed| awk '
BEGIN {
  MAX=1000
  N=MAX/2
  b=255
} {
  x=$5
  if(x<N) { # 青 -> 黒
    R=0
    G=R
    B=-b/N*x+b
  }
  else if (x>=N && x<2*N) { # 黒 -> 橙
    R=(x-N)/N*b
    G=R/2
    B=0
  }
  else if (x>=2*N) { # 橙
    R=255
    G=R/2
    B=0
  }
  $9=int(R)","int(G)","int(B)
  if ($5 > 1000) $5=1000
  print $0
}' > $baseFN.bed.tmp
  
$projectDir/bin/bedToBigBed -type=bed9 $baseFN.bed.tmp $gSize $baseFN.CUD.bb
rm $baseFN.bed.tmp

