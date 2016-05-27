#!/bin/sh
#$ -S /bin/sh

##########################################################################################################################################################################
#                                                      初期モード : GWAS, FANTOM のためのジョブを投入
##########################################################################################################################################################################
# qsub chipatlas/sh/analTools/preProcessed_insilicoChIP.sh initial

if [ $1 = "initial" ]; then
  rm -rf chipatlas/results/hg19/insilicoChIP_preProcessed
  rm -rf chipatlas/results/mm9/insilicoChIP_preProcessed
  mkdir chipatlas/results/hg19/insilicoChIP_preProcessed
  mkdir chipatlas/results/mm9/insilicoChIP_preProcessed
  
  qsub -N GWAS -o /dev/null -e /dev/null chipatlas/sh/analTools/insilicoChIP_GWAS.sh
  qsub -N FF_Enhancer -o /dev/null -e /dev/null chipatlas/sh/analTools/insilicoChIP_FantomEnhancer.sh
  qsub -N FF_Pr_hg19 -o /dev/null -e /dev/null chipatlas/sh/analTools/insilicoChIP_FantomPromoter.sh hg19
  qsub -N FF_Pr_mm9 -o /dev/null -e /dev/null chipatlas/sh/analTools/insilicoChIP_FantomPromoter.sh mm9
  exit
fi
##########################################################################################################################################################################
#                                                      処理モード : barchart や clustering のための前処理、後処理
##########################################################################################################################################################################
# sh chipatlas/sh/analTools/preProcessed_insilicoChIP.sh P gwas 3 hg19
# sh chipatlas/sh/analTools/preProcessed_insilicoChIP.sh P fantomEnhancer 5 hg19
# sh chipatlas/sh/analTools/preProcessed_insilicoChIP.sh P fantomPromoter 5 hg19 5000 5000

if [ $1 = "P" ]; then 
  anal=$2
  qVal=$3
  genome=$4
  up=$5      # fantomPromoter の場合のみ
  down=$6    # fantomPromoter の場合のみ
  
  # 不要なファイルの消去
  rm chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/tsv/*Overlap.bb &
  rm -r chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/tsv/*BED &
  
  # 指定した qVal 以下のデータを集計し、TSV ファイルを作成
  key="BloodBreastDigestive tractLungProstateCardiovascularLiverNeural"
  mkdir chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/summerized
  mkdir chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/df
  
  for tsv in `ls chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/tsv/*tsv| grep -v summerized`; do
    id=`basename $tsv| sed 's/\.tsv//g'`
    summerizedTSV="chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/summerized/$id.tsv"
    echo "disease nr cellType pval"| tr ' ' '\t' > $summerizedTSV
    cat $tsv| sort -t $'\t' -k9n| awk -F '\t' -v id="$id" -v qVal=$qVal -v key="$key" '{
      if(key !~ $4) $4 = "Others"
      if ($10 + 0 < - qVal) printf "%s\t%d\t%s\t%s\n", id, NR, $4, - $9
    }' >> $summerizedTSV
  done
  
  
  # 個々の id について計算
  ql=`sh chipatlas/sh/QSUB.sh mem`
  for tsv in `ls chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/tsv/*.tsv`; do
    id=`basename "$tsv"| sed 's/\.tsv$//'`
    if [ $anal = "fantomPromoter" ]; then
      nm="R_FP"$genome
      qsub $ql -o /dev/null -e /dev/null -N "$nm" chipatlas/sh/analTools/preProcessed_insilicoChIP.sh "$id" $anal $qVal $genome $up $down
    else
      nm=`echo "R_"$anal| cut -c1-10`
      qsub $ql -o /dev/null -e /dev/null -N "$nm" chipatlas/sh/analTools/preProcessed_insilicoChIP.sh "$id" $anal $qVal $genome
    fi
  done
  
  while :; do
    qN=`qstat| awk -v nm="$nm" 'nm == $3'| wc -l`
    if [ $qN -eq 0 ]; then
      break
    fi
  done
  
  
  # PNG や PDF の有無を整理
  fileList="chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/file01.tsv"
  {
    ls -l chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/tsv/*.html
    ls -l chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/tsv/*[0-9].tsv
    ls -l chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/tsv/*Overlap.bed
    ls -l chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/tsv/*.png
    ls -l chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/tsv/*.pdf
  }| awk '{
    N = split($10, a, "/")
    sub("_", ".", a[N])
    split(a[N], b, ".")
    id = b[1]
    prfx = substr(b[2], 1, 2)
    d[id]++
    if ($5 > 0) x[id, prfx]++
  } END {
    for (id in d) printf "%s\t%d\t%d\t%d\t%d\t%d\t%d\n", id, x[id, "ht"], x[id, "cl"], x[id, "ts"], x[id, "Ov"], x[id, "pn"], x[id, "pd"]
  }' > "$fileList"
  # id            html    cls.tsv  tsv     Overlap.bed  png     pdf
  # CL:0000127    1       0        1       1            0       0
  
  
  # 公開用 リスト (HTML) の作成
  id2name="chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/lib/ff5id2name.tab"
  gwasCatalog="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/gwasCatalog_original.bed"
  for tsv in `ls chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/tsv/*[0-9].tsv`; do
    id=`basename $tsv| sed 's/\.tsv//'`
    echo $id"@"`head -n1 $tsv| cut -f9,10`| tr '@ ' '\t\t'
  done| awk -F '\t' -v gwasCatalog="$gwasCatalog" -v id2name="$id2name" -v fileList="$fileList" -v genome=$genome -v anal=$anal '
  BEGIN {
    if (anal == "gwas") {  # gwas の場合
      while ((getline < gwasCatalog) > 0) a["GWAS:" $23] = $10
    } else {               # fantomEnhancer, fantomPromoter の場合
      while ((getline < id2name) > 0) a[$1] = toupper(substr($2, 1, 1)) substr($2, 2, 1000)
    }
    while ((getline < fileList) > 0) {
      for (i=2; i<=7; i++) f[$1, i] = $i
    }
  } {
    id = $1
    trait = a[id]
    gsub("%", "", trait)
    gwasQuery = trait
    
    if (anal == "fantomEnhancer") bedDir = "bed"
    if (anal == "fantomPromoter") bedDir = "geneList"
    if (anal == "gwas")           bedDir = "ldDhsBed"

    htmlUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/" genome "/insilicoChIP_preProcessed/" anal "/results/" id ".html"
    tsvUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/" genome "/insilicoChIP_preProcessed/" anal "/results/" id ".tsv"
    itsUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/" genome "/insilicoChIP_preProcessed/" anal "/results/" id "_Overlap.bed"
    pngUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/" genome "/insilicoChIP_preProcessed/" anal "/results/" id ".png"
    pdfUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/" genome "/insilicoChIP_preProcessed/" anal "/results/" id ".pdf"
    cltUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/" genome "/insilicoChIP_preProcessed/" anal "/results/" id ".cls.tsv"
    bedUrl = "http://dbarchive.biosciencedbc.jp/kyushu-u/" genome "/insilicoChIP_preProcessed/" anal "/bed/" id ".bed"
    wclbed = "cat chipatlas/results/" genome "/insilicoChIP_preProcessed/" anal "/" bedDir "/" id ".bed| wc -l"
    wclbed | getline num
    close(wclbed)
    gsub(" ", "%20", gwasQuery)
  
    if (anal == "gwas") {  # gwas の場合
      printf "<tr>\n<td><a target=\"_blank\" style=\"text-decoration: none\" href=\"https://www.ebi.ac.uk/gwas/search?query="
      printf "%s", gwasQuery
      printf "\"><i class=\"fa fa-info-circle\" title=\"liTitle\"></i> </a>"
      printf trait
    } else {               # fantomEnhancer, fantomPromoter の場合
      printf "<tr>\n<td><a target=\"_blank\" style=\"text-decoration: none\" href=\"http://fantom.gsc.riken.jp/5/sstar/"
      printf "%s", id
      printf "\"><i class=\"fa fa-info-circle\" title=\"liTitle\"></i> </a>"
      printf id "</td>\n<td>" trait
    }
    printf "</td>\n"
    
    printf "<td align=\"center\"><a target=\"_blank\" style=\"text-decoration: none\""
    if (f[id, 2] == 1) printf " href=\"%s", htmlUrl
    printf "\">HTML</a>, <a target=\"_blank\" style=\"text-decoration: none\" href=\""
    printf "%s", tsvUrl
    printf "\">TSV</a>, <a target=\"_blank\" style=\"text-decoration: none\" href=\""
    printf "%s", pngUrl
    printf "\">Image</a></td><td align=\"center\"><a target=\"_blank\" style=\"text-decoration: none\""
    if (f[id, 7] == 1) printf " href=\"%s", pdfUrl
    printf "\">Image</a>, <a target=\"_blank\" style=\"text-decoration: none\" href=\""
    printf "%s", cltUrl
    printf "\">TSV</a></td><td align=\"center\"><a target=\"_blank\" style=\"text-decoration: none\" href=\""
    printf "%s", itsUrl
    printf "\">BED</a></td>\n"
    
    printf "<td align=\"right\"><a target=\"_blank\" style=\"text-decoration: none\" href=\""
    printf "%s", bedUrl
    printf "\">%d</a></td>\n", num
    
    printf "<td align=\"right\">%.1f</td>\n", $2   # P-val
    printf "<td align=\"right\">%.1f</td>\n", $3  # Q-val
  }'| awk -v gwasList_template="chipatlas/sh/analTools/"$anal"List_template.html" '
  BEGIN {
    while ((getline < gwasList_template) > 0) {
      if ($1 == "__tbody__") break
      print
    }
    close(gwasList_template)
  } {
    print
  } END {
    while ((getline < gwasList_template) > 0) {
      if (j > 0) print
      if ($1 == "__tbody__") j = 1
    }
  }' > chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/"$anal"list.html
  
  
  # 結果 (HTML) にリンクを設ける
  for html in `ls chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/tsv/*.html`; do
    id=`basename $html| sed 's/\.html//'`
    newStr=`cat "chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/"$anal"list.html"| grep "$id"| grep "html"| sed 's/<td align="center">//g'| sed 's[</td>[@[g'`
    cat $html| sed 's[<p>Search for proteins significantly bound to your data\.</p>[['| awk -v id=$id -v newStr="$newStr" '
    BEGIN {
      split(newStr, a, "@")
    } {
      print $0
      if ($0 ~ "<caption><h2>") {
        printf "<caption>Downloads: Enrichment ("
        printf a[1]
        printf "), Clustering ("
        printf a[2]
        printf "), Intersections ("
        printf a[3]
        printf ")<br><br><br></caption>\n"
      }
    }' > $html"tmp"
    mv $html"tmp" $html
  done
  
  exit
fi

##########################################################################################################################################################################
#                                                      個別 id モード : R で barchart や clustering をおこなう
##########################################################################################################################################################################
# qsub chipatlas/sh/analTools/preProcessed_insilicoChIP.sh UBERON:0002106 gwas 3 hg19
# qsub chipatlas/sh/analTools/preProcessed_insilicoChIP.sh UBERON:0002106 fantomEnhancer 5 hg19
# qsub chipatlas/sh/analTools/preProcessed_insilicoChIP.sh UBERON:0002106 fantomPromoter 5 hg19 5000 5000

id="$1"
anal=$2
qVal=$3
genome=$4
up=$5      # fantomPromoter の場合のみ
down=$6    # fantomPromoter の場合のみ

# Overlap する BED ファイルを 整形する
case $anal in
  "gwas")
    gwasLD="chipatlas/results/hg19/insilicoChIP_preProcessed/gwas/lib/gwas_original+LD0.9.bed"
    bed="chipatlas/results/$genome/insilicoChIP_preProcessed/gwas/results/tsv/"$id"_Overlap.bed"
    extd=`grep extd "chipatlas/sh/analTools/insilicoChIP_GWAS.sh"| head -n1| cut -d '=' -f2`
    ID=`echo $id| cut -c6-`
    
    
    cat "$gwasLD"| awk -F '\t' -v OFS='\t' -v extd=$extd '{
      print $1, $25 - extd, $26 + extd, $4, $23
    }'| intersectBed -a "$bed" -b stdin -wa -wb| tr '@' '\t'| awk -F '\t' -v OFS='\t' -v ID="$ID" '  # chr10   101365262       101365356       CEBPB_     SRX150578        chr10   101357717       101366816       rs11190179      0001
    BEGIN {
      while ((getline < "chipatlas/lib/assembled_list/experimentList.tab") > 0) {
        for (i=4; i<=6; i++) x[$1, i] = $i
      }
    } {
      if (!a[$2,$3,$4,$5]++) {
        print $1, $2, $3, $5, x[$5, 4], x[$5, 5], x[$5, 6], $9  # chr11   9110514   9111008   SRX062358     AR    Prostate     LNCAP   rs2647528 (座位は LD-DHS)
      }
    }' > "$bed"tmp
    mv "$bed"tmp "$bed"
    ;;
  "fantomEnhancer")
    bed="chipatlas/results/$genome/insilicoChIP_preProcessed/fantomEnhancer/results/tsv/"$id"_Overlap.bed"
    cat "$bed"| sed 's/_@/@/'| tr '@' '\t'| awk -F '\t' -v OFS='\t' '
    BEGIN {
      while ((getline < "chipatlas/lib/assembled_list/experimentList.tab") > 0) {
        for (i=4; i<=6; i++) x[$1, i] = $i
      }
    } {
      print $1, $2, $3, $5, x[$5, 4], x[$5, 5], x[$5, 6]
    }' > "$bed"tmp
    mv "$bed"tmp "$bed"
    # chr1    7764543   7764931   SRX1165098    CREB1   Liver   Hep G2  (座位は Enhancer)
    ;;
  "fantomPromoter")
    tss="chipatlas/lib/TSS/uniqueTSS."$genome".bed"
    bed="chipatlas/results/$genome/insilicoChIP_preProcessed/fantomPromoter/results/tsv/"$id"_Overlap.bed"
    cat "$bed"| awk -v up=$up -v down=$down -v OFS='\t' -v tss="$tss" -F '\t' '
    BEGIN {
      while ((getline < tss) > 0) {
        beg = ($5 == "+")? $2 - up : $3 - down
        end = ($5 == "+")? $2 + down : $3 + up
        b[$1, beg, end] = $4          # b[chr9, 108087714, 108097714] = Bsn
        c[$1, beg, end] = $6 "\t" $5  # c[chr9, 108087714, 108097714] = NM_007567    +/-
      }
      while ((getline < "chipatlas/lib/assembled_list/experimentList.tab") > 0) {
        for (i=4; i<=6; i++) x[$1, i] = $i
      }
    } {
      split($4, r, "@")
      srx = r[2]
      print $1, $2, $3, srx, x[srx, 4], x[srx, 5], x[srx, 6], c[$1, $2, $3], b[$1, $2, $3]
    }' > "$bed"tmp
    #  chr12   86109062   86119062   SRX1115328   Gata3   Blood   Th2   NM_023409   -   Npc2
    #  <==      TSS ± 5kb      ==>   <==      Overlap する SRX     ==>   <== TSS の遺伝子 ==>
    mv $bed"tmp" $bed
    
    # geneList を BED にする (unique TSS とマッチするもの)
    gl="chipatlas/results/$genome/insilicoChIP_preProcessed/fantomPromoter/geneList/$id.geneList.txt"
    gb="chipatlas/results/$genome/insilicoChIP_preProcessed/fantomPromoter/geneList/$id.bed"
    cat $tss| awk -F '\t' -v OFS='\t' -v gl="$gl" '
    BEGIN {
      while ((getline < gl) > 0) x[$1]++
    } {
      if (!y[$4]++ && x[$4] > 0) print
    }' > "$gb"
    ;;
esac


# R で bar chart 描画
R-3.2.3/bin/R --vanilla --args "$anal" "$genome" "$id" << 'DDD'
  args <- commandArgs(trailingOnly = T)
  library("ggplot2")
  library(grid)
  library(RColorBrewer)
  
  anal <- args[1]
  genome <- args[2]
  id <- args[3]
  
  tsv <- paste("chipatlas/results/", genome, "/insilicoChIP_preProcessed/", anal, "/results/summerized/", id, ".tsv", sep="")
  data <- read.csv(tsv, sep="\t", header=T)
  
  ct <- data$cellType
  ctc <- c("Blood", "Breast", "Cardiovascular", "Digestive tract", "Liver", "Lung", "Neural", "Others", "Prostate")
  colP <- c(brewer.pal(9,"Set1")[c(1, 3, 4, 8, 7, 2, 6, 9, 5)])
  names(colP) <- ctc

  colp <- data.frame(
    ctc = names(summary(ct)),
    colP = colP[names(summary(ct))],
    num = summary(ct)
  )
  # Blood = 赤, Lung = 青, Breast = 緑, Cardiovascular = 紫, Prostate = オレンジ, Neural = 黄, Liver = 茶, Digestive tract = ピンク, Others = グレー

  png(paste("chipatlas/results/", genome, "/insilicoChIP_preProcessed/", anal, "/results/tsv/", id, ".png", sep=""), height=4800, width=4800, res=720)
  
  grid.newpage()
  g <- ggplot(
    data,
    aes (                  # ggplot オプション設定
      x = nr,           # x 軸を df$group とする
      y = pval,          # y 軸を df$length とする
      fill = cellType
    )
  )
  g <- g + geom_bar(                    # plotbarに当たる関数
    width = 1,
    stat = "identity"
  )
  gb <- g + theme(
    legend.position="none",
    panel.background = element_blank(),
    panel.grid.minor = element_blank(),
    axis.title.x = element_text(angle = 180, hjust = 0.5, vjust = 0.5),
    axis.text.x = element_text(angle = 90, hjust = 0.5, vjust = 0.5),
    axis.text.y = element_text(angle = 90, hjust = 0.5, vjust = 0.5),
    panel.background = element_blank()
  )
  
  gb <- gb + scale_fill_manual(values = as.character(subset(colp, colp$num > 0)$colP))
  gb <- gb + xlab("Rank") + ylab("−Log10(P-value)")
  
  print(gb)
  dev.off()
DDD


# PNG ファイルを時計回りに 90 度回転させる
png="chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/tsv/$id.png"
convert -rotate 90 "$png" "$png"tmp.png
mv "$png"tmp.png "$png"


# R でクラスター解析し、描画する
  # 結合部位と TFs のクラスター解析
  # 病気ごとに結合の有無を 0/1 で表す
tsv="chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/tsv/$id.tsv"
df="chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/df/$id.df"
cat "chipatlas/results/$genome/insilicoChIP_preProcessed/$anal/results/tsv/"$id"_Overlap.bed"| awk -F '\t' -v OFS='\t' -v tsv="$tsv" -v qVal=$qVal -v anal=$anal -v genome=$genome '
BEGIN {
  while ((getline < tsv) > 0) {
    if ($10 < - qVal) {
      s[$1]++
      p[$1] = $1 " | " $3 " | " $4 " | " $5
    }
  }
} {
  if (s[$4] > 0) {
    locus = $1 ":" $2 "-" $3
    c[locus]++
    x[locus, $4] = 1
  }
} END {
  printf "exp"
  for (locus in c) printf "\t%s", locus
  printf "\n"
  for (srx in p) {
    printf p[srx]
    for (locus in c) printf "\t%d", x[locus, srx]
    printf "\n"
  }
}' > "$df"


# df のうち、行 (SRX) または列 (locus) が２つ未満の場合は cluster 解析しない
clusterOK=`cat "$df"| awk -v df="$df" '{
  if (NR == 1) x = NF
} END {
  if (x > 2 && NR > 2) printf "1"
  else                 printf "0"
}'`

if [ $clusterOK = 0 ]; then
  exit
fi

# クラスター解析
R-3.2.3/bin/R --vanilla --args $anal $genome $id << 'DDD'
  args <- commandArgs(trailingOnly = T)
  library(reshape2)
  library(gplots)
  library(RColorBrewer)
  library(grid)
  
  anal <- args[1]
  genome <- args[2]
  id <- args[3]
  
  methD="euclidean"
  methH="complete"
  
  # 色の定義
  colN <- c(1, 3, 4, 8, 7, 2, 6, 9, 5, 0)
  colP <- c(brewer.pal(9,"Set1")[colN], "#eeeeee")
  colC <- c("Blood", "Breast", "Cardiovascular", "Digestive tract", "Liver", "Lung", "Neural", "Others", "Prostate", "NA")
  names(colN) <- colC
  names(colP) <- colN
    # Blood = 赤, Lung = 青, Breast = 緑, Cardiovascular = 紫, Prostate = オレンジ, Neural = 黄, Liver = 茶, Digestive tract = ピンク, Others = グレー
    
  # クラスタリング結果の PDF と TSV ファイルを作成
  fnPDF <- paste("chipatlas/results/", genome, "/insilicoChIP_preProcessed/", anal, "/results/tsv/", id, ".pdf", sep="")
  pdf(fnPDF, width = 70, height = 70)
  outtsv <- paste("chipatlas/results/", genome, "/insilicoChIP_preProcessed/", anal, "/results/tsv/", id, ".cls.tsv", sep="")
  system(paste('awk \'BEGIN {printf \"\t\"}\' > ', outtsv))

  # データの読み込みと整形
  dc <- read.table(paste("chipatlas/results/", genome, "/insilicoChIP_preProcessed/", anal, "/results/df/", id, ".df", sep=""), sep="\t", header = T)
  m <- data.matrix(dc[, colnames(dc) != "exp"]) # 行列型に変換 (列 "exp" は除去)
  rownames(m) <- dc$exp # 行の名前を追加
  
  m2 <- m
  m3 <- m
  
  # 行または列が１つしかないときはクラスタリングを行えない。######################
#    if (length(colnames(m3)) < 1 || length(rownames(m3)) < 1) {
#      system(paste("rm ", fnPDF, outtsv))
#      next
#    }
  # 距離の計算とクラスタリング
  d1<-dist(m, method=methD)
  d2<-dist(t(m), method=methD)
  c1 <- hclust(d1, method=methH)
  c2 <- hclust(d2, method=methH)
  
  # 実験 ID に Cell type class を割り当てる
  srx <- c(1, rownames(m))
  F <- 1
  for (L in strsplit(rownames(m) , " \\| ")) {
    F <- c(F, L[3])
  }
  names(F) <- srx
  F[is.na(charmatch(F, colC))] <- "Others"

  # Overlap した場合の値 (=1) を Cell type class の ID (colN) に置換する
  for (cClass in colC) {
    m2[F[rownames(m)] == cClass & m == 1] <- colN[cClass]
  }
  Q <- sort(unique(c(m2)))

  # Cell type class がない場合は繰り下げる
  j <- 0
  for (k in Q) {
    m3[m2 == k] <- j
    j <- j + 1
  }

  # ヒートマップ
  heatmap(
    m3,
    Colv=as.dendrogram(c2),
    Rowv=as.dendrogram(c1),
    scale="none",
    margins = c(20, 20),
    col=colP[as.character(Q)]
  )

  # 凡例
  par(fig = c(0, 0.1, 0.88, 0.98), mar=c(0,0,0,0), new=TRUE)
  plot(
    y = c(1:9),
    x = rep(1,9),
    pch=15, # 四角を描く
    cex=5,  # 四角の大きさ
    col=colP[as.character(colN[rev(colC[c(1:7, 9, 8)])])],
    axes=FALSE, xlab="", ylab=""
  )
  text(
    y = c(1:9),
    x = rep(1.02,9),
    labels=rev(colC[c(1:7, 9, 8)]),
    pos = 4
  )

  dev.off()
  
  # クラスタリング結果の TSV ファイルを作成
  lb1 <- c(c1$labels)[rev(c(c1$order))] # 行ラベル (SRX など)
  lb2 <- c(c2$labels)[c(c2$order)] # 列ラベル (ゲノム座位)
  
  # クラスタリング結果のマトリクスを作る
  m4 <- matrix(
    m2[rev(c1$order), c2$order],
    nrow = length(c1$order),
    ncol = length(c2$order)
  )
  colnames(m4) <- lb2
  rownames(m4) <- lb1
  
  # Overlap した Cell class に置換
  j <- 0
  for (cls in colC) {
    j <- j + 1
    m4[m4 == j] <- colC[which(colN == j)]
  }
  m4[m4 == 0] <- "NA"
  
  # 書き出し
  write.table(m4, quote = FALSE, sep = "\t", file=outtsv, append = TRUE)
DDD





