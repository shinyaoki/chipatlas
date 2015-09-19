# gencodev19.longPolyA.cell.txt の入手先
# http://genome.crg.es/~sdjebali/Gencode/version19/GeneExpression/gencodev19_genes_with_RPKM_and_npIDR_oct2014.txt.gz

width=5000
bedL="chipatlas/results/hg19/public/ALL.ALL.20.AllAg.AllCell.bed"
for Cell in A549 AG04450 BJ CD20+ GM12878 H1-hESC HSMM HUVEC HeLa-S3 HepG2 IMR90 K562 MCF-7 Monocytes-CD14+ NHEK NHLF SK-N-SH SK-N-SH_RA; do
  bedA=test/$Cell.A.bed
  bedB=test/$Cell.B.bed
  outF=test/$Cell.tsv
  cat gencodev19.longPolyA.cell.txt| awk -F '\t' -v Cell=$Cell '{
    if (NR == 1) for (i=1; $i !~ Cell; i++) k++
    else {
      g[$2]++
      for (i=1; i<=NF; i++) x[$2,i] = $i
    }
  } END {
    for (gene in g) {
      delete v
      Sum = 0
      for (j=3; j<=NF; j++) {
        Sum += x[gene, j]
        for (z=1; z<=2; z++) {
          if (x[gene, j] < x[gene, k+z]) v[z]++
        }
      }
      Fold = ((x[gene, k+1] + x[gene, k+2])/2) / (0.0001 + (Sum - x[gene, k+1] - x[gene, k+2]) / (NF-4))
      if (v[1] * v[2] == (NF-3)*(NF-4) && x[gene, k+1] > 10 && x[gene, k+2] > 10) print Fold "\t" gene
    }
  }'| sort -k1nr| cut -f2| awk -F '\t' '
  BEGIN {
    while ((getline < "chipatlas/lib/TSS/uniqueTSS.hg19.bed") > 0) if ($6 ~ "NM_") T[$4]++   # T["LEFTY1"]++
  } {
    if (T[$1] > 0) print
  }'| head -n50| awk -F '\t' -v width=$width -v bedA=$bedA -v bedB=$bedB '
  BEGIN {
    while ((getline < "chipatlas/lib/TSS/uniqueTSS.hg19.bed") > 0) {
      if ($5 == "+") x[$4] = $1 "\t" $2-width "\t" $2+width
      else           x[$4] = $1 "\t" $3-width "\t" $3+width
    }
  } {
    print x[$1] > bedA
    delete x[$1]
  } END {
    for (gene in x) print x[gene] > bedB
  }'
  qsub -o /dev/null -e /dev/null -l short -l s_vmem=8G,mem_req=8G chipatlas/sh/analTools/bedToBoundProteins.sh $bedA $bedB $bedL $outF
done

for Cell in A549 AG04450 BJ CD20+ GM12878 H1-hESC HSMM HUVEC HeLa-S3 HepG2 IMR90 K562 MCF-7 Monocytes-CD14+ NHEK NHLF SK-N-SH SK-N-SH_RA; do
  tsv=test/$Cell.tsv
  htm=`echo $tsv| sed 's/tsv/html/'`
  sh chipatlas/sh/analTools/btbpToHtml.sh $tsv "$Cell genes" "Other genes" "$Cell vs Others" > $htm
done
# sh chipatlas/sh/analTools/btbpToHtml.sh inTSV TargetName ReferenceName
