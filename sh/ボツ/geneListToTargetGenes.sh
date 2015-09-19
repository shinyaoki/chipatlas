cat << DDD > geneList.txt
PITX2
ETS2
ZNF664-FAM101A
ZNF664
CCDC92
SLC7A5
NEURL1B
NBL1
SMAD7
PMEPA1
NSUN6
LEFTY1
LEFTY2
DDD


cat Gifford.tab| awk -F '\t' '{
  if ($5 == "HUES64" && $6 ~ "Endo" && $14 == "yes")
  if ($8 < $9 && $8 + $9 > 10 && $10*$10 > 16) print $1 "\t" $13 "\t" $8 "\t" $9 "\t" $10
}'| sort -k2n| uniq > geneList.txt



cat Xie.tab| awk -F '\t' '{
  if ($1 == "IMR90" && $8 > 20) print $2
}'| sort| uniq > geneList.txt

cat Chang.tab| awk -F '\t' '$4 ~ "Liver" {print $2}' > geneList.txt
  
cat SB_Up.tab  > geneList.txt
cat SB_Down.tab > geneList.txt


curl "http://www.wikicell.org/index.php/Liver_TS_Genes"| grep "<td>TL"| tr '>' '<'| cut -d '<' -f11 > geneList.txt






Ntss=`cat chipatlas/lib/TSS/TSS.hg19.bed | awk '$5 ~ "NM_"'| awk '!a[$4]++'| wc -l`
qVal=300  # qVal threshold
cat chipatlas/results/hg19/targetGenes/STRING_*.5.tsv| awk -F '\t' -v qVal=$qVal -v Ntss=$Ntss '
BEGIN {
  while ((getline < "chipatlas/lib/TSS/TSS.hg19.bed") > 0) {
    if ($5 ~ "NM_") T[$4]++   # T["LEFTY1"]++
  }
  while ((getline < "geneList.txt") > 0) {
    if (T[$1] > 0) {
      g[$1]++   # g["LEFTY1"]++
      NQ++
    }
  }
} {
  if ($1 == "Target_genes") {
    delete srx
    for (i=3; i<NF; i++) {
      split($i, a, "|")  # a[1] = SRX011573
      srx[i] = a[1]      # srx[nf] = SRX011573
      SRX[a[1]]++        # SRX[SRX011573]++
    }
  } else {
    for (i=3; i<NF; i++) {
      if ($i > qVal) x[$1,srx[i]]++   # x["LAMA3", "SRX011573"]++
    }
  }
} END {
  for (key in x) {
    split(key, b, SUBSEP)   # b[1] = LAMA3, b[2] = SRX011573
    if (g[b[1]] > 0) {
      G[b[2]] = G[b[2]] "," b[1]
      A[b[2]]++                # A["SRX011573"]++
    }
    else C[b[2]]++             # C["SRX011574"]++
  }
  for (key in A) printf "%s\t%s\t%s\t%s\t%s\t%f\t%s\n", key, A[key], NQ - A[key], C[key], Ntss - NQ - C[key], (A[key]/NQ) / ((A[key] + C[key]) / Ntss), G[key]
}'| tee test_gl.txt| awk '{
  print "echo " $1 " `fisher -p " $2 " " $3 " " $4 " " $5 "` " $6 " " $7 " " $2 " " $3 " " $4 " " $5
}'| sh| tr ' ' '\t'| awk -F '\t' '
BEGIN {
  cmd = "cut -c2-| tr \047,\047 \047\n\047| sort| tr \047\n\047 \047,\047"
  while((getline < "chipatlas/lib/assembled_list/experimentList.tab") > 0) {
    a[$1] = $4
    b[$1] = $5 "/" $6
  }
} {
  print $4 |& cmd
  close(cmd, "to")
  while((cmd |& getline var) > 0) x = substr(var, 1, length(var)-1)
  print log($2)/log(10) "\t" $1 "\t" a[$1] "\t" b[$1] "\t" $3 "\t" $5 "/" $5+$6 "\t" $7 "/" $7+$8 "\t" x
  close(cmd)
}'| sort -k1n| tee aaaaa| cut -f1-7| awk -F '\t' '$5 > 1'


cat aaaaa| awk -F '\t' '{
  S[NR] = $0
  p[NR] = exp($1*log(10))
} END {
  for (q = 0.5; q<=0.05; q = q/10) {2[
    for (i=NR; i>0; i--) {
      if (p[i] > q * i / NR) v[i] = v[i] "z"
    }
  }
  for (i=1; i<=NR; i++) print v[i] "\t" S[i]
}'
(1) N個の帰無仮説を、p値の小さい順に並べ、p1 ≦ p2 ≦ p3 ≦・・・≦ pNに相当する帰無仮説をH1、H2、H3・・・、HNと定義します。
(2) i = Nとする。
(3) Pi ≦ q X i/N を満たすならば、k = iとして(4)に進みます。そうでなければ、iにi-1を代入して、この手順を繰り返します。なお、i = 1まで達したならば、どの帰無仮説も棄却する事なく終了します。
(4) H1、H2、H3・・・、Hkを棄却します。


> xxxxx

cat aaaaa | cut -f1-7| awk -F '\t' '$5 > 1'




