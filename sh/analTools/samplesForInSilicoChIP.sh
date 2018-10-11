mkdir sample4insilicoChIP
for g in ce10 dm3 hg19 mm9 rn6 sacCer3; do
  mkdir sample4insilicoChIP/$g
done

Genome="hg19"
cat chipatlas/results/$Genome/Bed20/Bed/SRX022570.20.bed | randPickBed -n 1000| cut -f1-3 > sample4insilicoChIP/$Genome/bedA.txt  # AR   Prostate LNCAP
cat chipatlas/results/$Genome/Bed20/Bed/SRX199867.20.bed | randPickBed -n 2000| cut -f1-3 > sample4insilicoChIP/$Genome/bedB.txt  # CTCF Prostate LNCAP
tail -n+2 chipatlas/results/$Genome/targetGenes/POU5F1.5.tsv | cut -f1| grep -v '[^a-zA-Z0-9]'| head -n100| sort > sample4insilicoChIP/$Genome/geneA.txt  # POU5F1 の下流
tail -n+2 chipatlas/results/$Genome/targetGenes/SUZ12.5.tsv  | cut -f1| grep -v '[^a-zA-Z0-9]'| head -n150| sort > sample4insilicoChIP/$Genome/geneB.txt  # SUZ12 の下流

Genome="mm9"
cat chipatlas/results/$Genome/Bed20/Bed/SRX213830.20.bed | randPickBed -n 1000| cut -f1-3 > sample4insilicoChIP/$Genome/bedA.txt  # Pou5f1  Pluripotent stem cell   Embryonic Stem Cells
cat chipatlas/results/$Genome/Bed20/Bed/SRX080167.20.bed | randPickBed -n 2000| cut -f1-3 > sample4insilicoChIP/$Genome/bedB.txt  # Ctcf    Pluripotent stem cell   Embryonic Stem Cells
tail -n+2 chipatlas/results/$Genome/targetGenes/Pou5f1.5.tsv | cut -f1| grep -v '[^a-zA-Z0-9]'| head -n100| sort > sample4insilicoChIP/$Genome/geneA.txt  # Pou5f1 の下流
tail -n+2 chipatlas/results/$Genome/targetGenes/Suz12.5.tsv  | cut -f1| grep -v '[^a-zA-Z0-9]'| head -n150| sort > sample4insilicoChIP/$Genome/geneB.txt  # Suz12 の下流

Genome="rn6"
cat chipatlas/results/$Genome/Bed20/Bed/SRX1068228.20.bed | randPickBed -n 1000| cut -f1-3 > sample4insilicoChIP/$Genome/bedA.txt  # Sox6    Bone      Chondrosarcoma
cat chipatlas/results/$Genome/Bed20/Bed/SRX1774917.20.bed | randPickBed -n 2000| cut -f1-3 > sample4insilicoChIP/$Genome/bedB.txt  # Mlxipl  Pancreas  INS-1E
tail -n+2 chipatlas/results/$Genome/targetGenes/Sox6.5.tsv | cut -f1| grep -v '[^a-zA-Z0-9]'| grep -v CG| head -n100| sort -f > sample4insilicoChIP/$Genome/geneA.txt  # twi の下流
tail -n+2 chipatlas/results/$Genome/targetGenes/Mlxipl.5.tsv | cut -f1| grep -v '[^a-zA-Z0-9]'| grep -v CG| head -n150| sort -f > sample4insilicoChIP/$Genome/geneB.txt  # trx の下流

Genome="dm3"
cat chipatlas/results/$Genome/Bed20/Bed/SRX183882.20.bed | randPickBed -n 1000| cut -f1-3 > sample4insilicoChIP/$Genome/bedA.txt  # twi     Embryo  2-4h embryos
cat chipatlas/results/$Genome/Bed20/Bed/SRX027829.20.bed | randPickBed -n 2000| cut -f1-3 > sample4insilicoChIP/$Genome/bedB.txt  # trx     Cell line       S2
tail -n+2 chipatlas/results/$Genome/targetGenes/twi.5.tsv | cut -f1| grep -v '[^a-zA-Z0-9]'| grep -v CG| head -n100| sort -f > sample4insilicoChIP/$Genome/geneA.txt  # twi の下流
tail -n+2 chipatlas/results/$Genome/targetGenes/trx.5.tsv | cut -f1| grep -v '[^a-zA-Z0-9]'| grep -v CG| head -n150| sort -f > sample4insilicoChIP/$Genome/geneB.txt  # trx の下流

Genome="ce10"
cat chipatlas/results/$Genome/Bed20/Bed/SRX312080.20.bed | randPickBed -n 1000| cut -f1-3 > sample4insilicoChIP/$Genome/bedA.txt  # kle-2   Embryo  Embryos
cat chipatlas/results/$Genome/Bed20/Bed/SRX065628.20.bed | randPickBed -n 2000| cut -f1-3 > sample4insilicoChIP/$Genome/bedB.txt  # pha-4   Larvae  L3
tail -n+2 chipatlas/results/$Genome/targetGenes/kle-2.5.tsv | cut -f1| grep -v '\.'| grep -v CG| head -n100| sort -f > sample4insilicoChIP/$Genome/geneA.txt  # ESA1 の下流
tail -n+2 chipatlas/results/$Genome/targetGenes/pha-4.5.tsv | cut -f1| grep -v '\.'| grep -v CG| head -n150| sort -f > sample4insilicoChIP/$Genome/geneB.txt  # HST4 の下流

Genome="sacCer3"
cat chipatlas/results/$Genome/Bed20/Bed/SRX377177.20.bed | randPickBed -n 1000| cut -f1-3 > sample4insilicoChIP/$Genome/bedA.txt  # ESA1    Yeast strain    ZKY428
cat chipatlas/results/$Genome/Bed20/Bed/SRX193144.20.bed | randPickBed -n 2000| cut -f1-3 > sample4insilicoChIP/$Genome/bedB.txt  # HST4    Yeast strain    ML1
tail -n+2 chipatlas/results/$Genome/targetGenes/ESA1.5.tsv | cut -f1| grep -v '[^a-zA-Z0-9]'| grep -v CG| head -n100| sort -f > sample4insilicoChIP/$Genome/geneA.txt  # ESA1 の下流
tail -n+2 chipatlas/results/$Genome/targetGenes/HST4.5.tsv | cut -f1| grep -v '[^a-zA-Z0-9]'| grep -v CG| head -n150| sort -f > sample4insilicoChIP/$Genome/geneB.txt  # HST4 の下流


for Genome in ce10 dm3 hg19 mm9 rn6 sacCer3; do
  echo TRTTTACTTW > sample4insilicoChIP/$Genome/motifA.txt
  echo TRTTTGCTGA > sample4insilicoChIP/$Genome/motifB.txt
done
