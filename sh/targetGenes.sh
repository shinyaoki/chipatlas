#!/bin/sh
#$ -S /bin/sh

# 初期モード
# sh chipatlas/sh/targetGenes.sh INITIAL chipatlas

projectDir=$2
bedtools="$projectDir/bin/bedtools-2.17.0/bin/bedtools"
Width="10000 5000 1000"
qVal=`cat $projectDir/sh/preferences.txt| awk '$1 == "qVal" {printf "%s", $2}'`  # 最小の qVal

if [ $1 = "INITIAL" ]; then
  GENOME=`ls $projectDir/results`
  for Genome in $GENOME; do
    tgDir="$projectDir/results/$Genome/targetGenes"
    rm -rf $tgDir tmpDirForTargetGenes
    mkdir $tgDir tmpDirForTargetGenes
  done
  
  short=`sh $projectDir/sh/QSUB.sh shortOrweek`
  for TF_Genome in `cat $projectDir/lib/assembled_list/fileList.tab| awk -F '\t' -v GENOME="$GENOME" -v projectDir=$projectDir '
  BEGIN {
    N = split(GENOME, g, " ")
    for (i=1; i<=N; i++) {
      geneList = projectDir "/lib/geneList/" g[i] ".txt"
      while ((getline < geneList) > 0) TG[$1,g[i]]++  # TG["POU5F1","hg19"]++
      close(geneList)
    }
  } {
    if ($3 == "TFs and others" && TG[$4,$2] > 0) {  # $3 = 抗原大, $4 = 抗原小, $2 = Genome
      TG[$4,$2] = 0   # 重複を避ける
      print $4 "|" $2
    }
  }'`; do
    qsub -o /dev/null -e /dev/null $short $projectDir/sh/targetGenes.sh $TF_Genome $projectDir  # TF_Genome = POU5F1|hg19
  done
  exit
fi

####################################################################################################################################
#                                                             以下、qsub モード
####################################################################################################################################
qProt=`echo $1| cut -d '|' -f1`   # POU5F1
Genome=`echo $1| cut -d '|' -f2`  # hg19
stringList="$projectDir/lib/string/protein.actions.v10.$Genome.txt"
jobDir="tmpDirForTargetGenes/$JOB_ID"
mkdir $jobDir

srxCell=`cat $projectDir/lib/assembled_list/experimentList.tab| awk -F '\t' -v qProt="$qProt" -v Genome="$Genome" '{
  if($4 == qProt && $2 == Genome) {
    gsub(" ", "_", $6)
    print $1 "\t" $6    
  }
}'| sort -k1n| sort -k2f| tr '\t\n' '| '`  # 細胞名 -> SRX の順にソート
# srxCell="SRX130060|BJ SRX185775|BJ SRX011571|hESC_H1 SRX011572|hESC_H1 SRX017276|hESC_H1 SRX100483|hESC_H1 SRX021069|hESC_H9"

for width in $Width; do
  let wkb=$width/1000
  outTSV="$jobDir/$qProt.$wkb.tsv"
  for SRXCELL in `echo $srxCell`; do      # SRXCELL = SRX011571|hESC_H1
    srx=`echo $SRXCELL| cut -d '|' -f1`   # srx = SRX011571
    echo "$SRXCELL"
    $bedtools window -a $projectDir/results/$Genome/Bed$qVal/Bed/$srx.$qVal.bed -b $projectDir/lib/TSS/TSS.$Genome.bed -w $width| sort -k5n| awk -F '\t' '{
      if($15 ~ "NM_") arr[$14] = $5   # coding gene のみ抽出  arr[GH1] = 4065
    } END {
      for (key in arr) print key "\t" arr[key]  # SRX123445|NCCIT
    }'| sort -k2nr| awk '{                      # GH1    4065  1
      printf "%s\t%s\t%s\n", $1, $2, NR         # DERL3  2938  2
    }'                                          # ADI1   2503  3
  done| awk -v JOB_ID=$JOB_ID '{
    print
    if (nf < NF) nf = NF
  } END {
    if (nf < 2) system ("qdel " JOB_ID)  # もし bed05 がすべてゼロの場合は強制終了
  }'| awk -F '\t' -v srxCell="$srxCell" -v qProt="$qProt" -v stringList=$stringList '
  BEGIN {
    while ((getline < stringList) > 0) {      # stringList の内容: POU5F1  CDX2  expression  inhibition  1  800
      if ($3 == "expression" && $5 == 1) {    # && $5 == 1 も加えると方向性も区別
        if (String[$1,$2] < $6) String[$1,$2] = $6    # 同じ抗原の組み合わせの binding が複数あるときは最大値を採用
      }                                               # String["POU5F1","CDX2"] = 800
    }
  } {
    if (NF == 1) {
      srx = $1
      next      # レコードが SRX123445|NCCIT などの場合は srx = SRX123445|NCCIT として、next
    }
    arr[$1,srx] = $2  # arr["GH1","SRX123445|NCCIT"] = 4065
    GENE[$1]++        # GENE["GH1"]++
  } END {
    # ヘッダ部の作成
    N = split(srxCell, srxcell, " ")  # N = qProt の SRX の数, srxcell[1] = SRX130060|BJ
    printf "Target_genes\t%s|Average", qProt
    for (i=1; i<=N; i++) {
      printf "\t%s", srxcell[i]
    }
    printf "\tSTRING\n"
    
    # テーブル部の作成: ChIP-Atlas の結果
    cmd2 = "sort -nr -k" N+2 " -k" N+3
    for (gene in GENE) {
      printf "%s", gene |& cmd2   # gene = target gene
      Sum = 0
      for (i=1; i<=N; i++) {
        printf "\t%d", arr[gene,srxcell[i]] |& cmd2
        Sum += arr[gene,srxcell[i]]
      }
      printf "\t%f\t%d\n", Sum / N, String[qProt,gene] |& cmd2  # 平均値と STRING 値
    }
    
    # テーブル部の作成: STRING のみの予測を出力   String["POU5F1","CDX2"] = 800
    for (key in String) {
      split(key, TF, SUBSEP)   # TF[1] = qProt, TF[2] = target gene
      if (String[key] > 0 && TF[1] == qProt && GENE[TF[2]] < 1) {
        printf "%s", TF[2] |& cmd2
        for (i=0; i<=N; i++) printf "\t0" |& cmd2
        printf "\t%d\n", String[qProt,TF[2]] |& cmd2
      }
    }
    close(cmd2, "to")
    
    # テーブル部の作成: 平均値でソートして出力
    while ((cmd2 |& getline) > 0) {
      printf "%s\t%f\t", $1, $(N+2)               # Target gene name, Average
      for (i=1; i<=N; i++) printf "%d\t", $(i+1)  # MACS2 qVal
      printf "%d\n", $(N+3)                       # STRING 値
    }
  }' > "$outTSV"
  
  if [ `cat "$outTSV"| wc -l` -eq 0 ]; then
    exit
  fi
  
  # outTSV を各 SRX 列でソートする
  Header=`head -n1 "$outTSV"`
  NF=`echo "$Header"| awk '{printf "%d", NF}'`
  i=2
  
  for srxCELL in `echo "$Header"| cut -f3-`; do   # srxCELL = SRX130060|BJ
    let i=$i+1
    SRX=`echo "$srxCELL"| cut -d '|' -f1`
    echo "$Header" > "$jobDir/$SRX.$wkb.tsv"
    tail -n+2 "$outTSV"| sort -nr -k"$i" -k2 -k"$NF" >> "$jobDir/$SRX.$wkb.tsv"
  done
  mv "$jobDir/$SRX.$wkb.tsv" "$jobDir/STRING_$qProt.$wkb.tsv" # 一番最後は STRING でソートしたものなので、ファイル名を STRING_TF.tsv に変更
  
  # html 形式に変換
  for tsv in `ls "$jobDir/"*tsv`; do            # tsv の種類: 抗原.tsv,  SRX.tsv,  STRING_抗原.tsv
    SRX=`basename "$tsv"| cut -d '.' -f1`       # SRX の種類: 抗原,      SRX,      STRING_抗原
    outfn=`echo "$tsv"| sed 's/\.tsv$/.html/'`  #html の種類: 抗原.html, SRX.html, STRING_抗原.html
    sh $projectDir/sh/tgToHtml.sh "$tsv" $Genome > "$outfn"
    mv "$tsv" $projectDir/results/$Genome/targetGenes/
    mv "$outfn" $projectDir/results/$Genome/targetGenes/
  done
done



