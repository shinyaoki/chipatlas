#!/bin/sh
#$ -S /bin/sh

projectDir=xhipome_ver3
Genome=hg19
bedtools="$projectDir/bin/bedtools-2.17.0/bin/bedtools"

Fisher() {
  echo "$1 $2 $3 $4"| awk '{
    a = $1
    b = $2
    c = $3
    d = $4
    ab = a+b
    cd = c+d
    ac = a+c
    bd = b+d
    n = ab+cd
    for (i = 1; i <= n; i++) {
        q[i] = q[i-1]+log(i)
    }
    x = q[ab]+q[cd]+q[ac]+q[bd]-q[n]
    maxa = (ab <= ac) ? ab : ac
    mina = ab-((ab <= bd) ? ab : bd)
    adbc = a*d-b*c
    for (i = mina; i <= maxa; i++) {
        b = ab-i
        c = ac-i
        d = bd-b
        adbc1 = i*d-b*c
        p = exp(x-(q[i]+q[b]+q[c]+q[d]))
        if (abs(adbc1) >= abs(adbc)) {
            p2 += p
        }
    }
    printf "%.6g\n", p2
  }
  
  # x の絶対値を求める
  # 使用例： x = abs(-10.95)
  
  function abs(x) {
     return (x < 0) ? -x : x
  }'| awk '{
    if ($1 == 0) printf "-324"
    else         printf "%f", log($1)/log(10)
  }'
}

intersection() { # $1 = bedA; $2 = bedB
  bedA=$1
  bedB=$2
  a=`$bedtools intersect -a $bedA -b $bedB| wc -l`
  b=$(for i in `seq 10`; do
        $bedtools shuffle -i $bedB -g $projectDir/lib/genome_size/$Genome.chrom.sizes
      done| $bedtools intersect -a $bedA -b stdin| wc -l)
  AC=`cat $bedB| wc -l`
  let c=$AC-$a
  let d=10*$AC-$b
  Fisher $a $b $c $d 2>/dev/null
}

qVal=20
inBn="aaa/ALL.PSC.$qVal.AllAg.AllCell"
cat $inBn.AG.html| awk '{if($1!="" && $1 !~ ":") print "[" $1 "]_"}' > $inBn.ag.tmp   # [NANOG]_
fgrep -f $inBn.ag.tmp $inBn.bed| tr '[]' '\t\t'| cut -f5,9| awk '!a[$0]++' > $inBn.SRX.tmp  # NANOG	SRX266862

# for qProt in `awk '!a[$1]++ {print $1}' $inBn.SRX.tmp` # qProt = POU5F1

qProt=FOXH1
for qSRX in `awk -v qProt=$qProt '{if ($1 == qProt) print $2}' $inBn.SRX.tmp`; do  # qSRX =	SRX266862
  for pair in `cat $inBn.SRX.tmp| tr '\t' '!'`; do     # pair = NANOG!SRX266862
    {
      echo $qProt
      echo $qSRX
      oSRX=`echo $pair| cut -d '!' -f2`
      echo $pair| tr '!' '\n'
      intersection $projectDir/results/$Genome/Bed$qVal/Bed/$qSRX.$qVal.bed $projectDir/results/$Genome/Bed$qVal/Bed/$oSRX.$qVal.bed
    }| tr '\n' '\t'
    echo ""
  done # POU5F1	SRX266859	NANOG	SRX266862	-324
done > $qProt.txt

cat $qProt.txt| awk -F '\t' -v qProt=$qProt '{
  NumA[$3]++
  pSumA[$3] = pSumA[$3] + $5
  NumB[$4]++
  pSumB[$4] = pSumB[$4] + $5
} END {
  inFn = qProt ".txt"
  while ((getline < inFn) > 0) {
    print $0 "\t" pSumA[$3] / NumA[$3] "\t" pSumB[$4] / NumB[$4]
  }
}'| sort -k6n -k7n -k4 -k2| awk -F '\t' -v qProt=$qProt '{
  if(!a[$1]++) printf "\t%s", $1
  if(!b[$2]++) printf "\t%s", $2
  Line[NR] = $0
} END {
  printf "\n"
  for (i=1; i<=NR; i++) print Line[i]
}'| awk -F '\t' '{
  if (NR == 1) {
    sub("\t", "", $0)
    printf "%s\tGroup_Avr\tEach_Avr", $1
    for (i=2; i<=NF; i++) printf "\t%s", $i
    printf "\n"
    qPnum = NF - 1
  } else {
    n++
    if (n==1) printf "%s/%s\t%f\t%f", $3, $4, $6, $7
    printf "\t%s", $5
    if (n==qPnum) {
      printf "\n"
      n=0
    }
  }
}' > $qProt.tab

# Group_Avr でソート
# FOXH1	Group_Avr	Each_Avr	SRX064484	SRX064493
# FOXH1/SRX064484	-324	-324	-324	-324
# FOXH1/SRX064484	-324	-324	-324	-324
# EOMES/SRX035159	-322.318	-322.318	-320.636898	-324
# FOXA2/SRX266855	-190.277	-218.247	-112.494354	-324
# FOXA2/SRX266856	-190.277	-162.306	-78.818274	-245.79459